package expo.modules.applemusic

import android.os.Handler
import com.apple.android.music.playback.controller.MediaPlayerController
import com.apple.android.music.playback.model.MediaPlayerException
import com.apple.android.music.playback.model.PlayerQueueItem
import com.apple.android.music.playback.queue.PlaybackQueueInsertionType
import com.apple.android.music.playback.queue.PlaybackQueueItemProvider
import expo.modules.kotlin.exception.CodedException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * [MediaPlayerController.prepare] loads queue items asynchronously — wait for
 * [MediaPlayerController.Listener.onPlaybackQueueItemsAdded] before returning to JS.
 */
internal object PlaybackQueuePrepare {
  private const val PREPARE_TIMEOUT_MS = 20_000L

  suspend fun prepare(
    appContext: android.content.Context,
    mainHandler: Handler,
    session: PlaybackSession,
    provider: PlaybackQueueItemProvider,
    musicUserToken: String? = null,
  ) {
    AndroidDeveloperToken.requireStored(appContext)
    val stack = AppleMusicRestStack.create(appContext)
    val effectiveToken = resolvePlaybackMusicUserToken(appContext, musicUserToken)
    stack.storefront.requireUserStorefront(effectiveToken)
    withContext(Dispatchers.Main) {
      val player = session.ensurePlaybackController(effectiveToken)
      suspendCancellableCoroutine { continuation ->
        lateinit var timeoutRunnable: Runnable

        val prepareListener =
          object : MediaPlayerController.Listener {
            private fun cleanup() {
              player.removeListener(this)
              mainHandler.removeCallbacks(timeoutRunnable)
            }

            private fun finishSuccess() {
              if (!continuation.isActive) return
              cleanup()
              continuation.resume(Unit)
            }

            private fun finishError(error: Exception) {
              if (!continuation.isActive) return
              cleanup()
              continuation.resumeWithException(PlaybackErrorMapper.map(error))
            }

            override fun onPlaybackQueueItemsAdded(
              player: MediaPlayerController,
              queueInsertionType: Int,
              containerIndex: Int,
              itemCount: Int,
            ) {
              if (itemCount > 0) finishSuccess()
            }

            override fun onPlaybackError(
              player: MediaPlayerController,
              error: MediaPlayerException,
            ) {
              finishError(error)
            }

            override fun onPlayerStateRestored(player: MediaPlayerController) {}
            override fun onPlaybackStateChanged(
              player: MediaPlayerController,
              previousState: Int,
              newState: Int,
            ) {
            }
            override fun onPlaybackStateUpdated(player: MediaPlayerController) {}
            override fun onBufferingStateChanged(player: MediaPlayerController, buffering: Boolean) {}
            override fun onCurrentItemChanged(
              player: MediaPlayerController,
              previous: PlayerQueueItem?,
              current: PlayerQueueItem?,
            ) {
            }
            override fun onItemEnded(
              player: MediaPlayerController,
              item: PlayerQueueItem,
              endPosition: Long,
            ) {
            }
            override fun onMetadataUpdated(player: MediaPlayerController, item: PlayerQueueItem) {}
            override fun onPlaybackQueueChanged(
              player: MediaPlayerController,
              items: MutableList<PlayerQueueItem>,
            ) {
            }
            override fun onPlaybackRepeatModeChanged(player: MediaPlayerController, mode: Int) {}
            override fun onPlaybackShuffleModeChanged(player: MediaPlayerController, mode: Int) {}
          }

        timeoutRunnable =
          Runnable {
            if (!continuation.isActive) return@Runnable
            player.removeListener(prepareListener)
            if (player.playbackQueueItemCount > 0) {
              continuation.resume(Unit)
            } else {
              continuation.resumeWithException(
                CodedException(
                  AppleMusicErrorCodes.PLAYBACK_ERROR,
                  "Playback queue stayed empty after prepare",
                  null,
                ),
              )
            }
          }

        continuation.invokeOnCancellation {
          player.removeListener(prepareListener)
          mainHandler.removeCallbacks(timeoutRunnable)
        }

        player.addListener(prepareListener)
        mainHandler.postDelayed(timeoutRunnable, PREPARE_TIMEOUT_MS)

        try {
          player.prepare(
            provider,
            PlaybackQueueInsertionType.INSERTION_TYPE_CLEAR_AND_REPLACE,
            true,
          )
        } catch (error: Exception) {
          player.removeListener(prepareListener)
          mainHandler.removeCallbacks(timeoutRunnable)
          if (continuation.isActive) {
            continuation.resumeWithException(PlaybackErrorMapper.map(error))
          }
        }
      }
    }
  }
}
