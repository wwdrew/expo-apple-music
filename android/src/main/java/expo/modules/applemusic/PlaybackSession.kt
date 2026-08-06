package expo.modules.applemusic

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.apple.android.music.playback.controller.MediaPlayerController
import com.apple.android.music.playback.controller.MediaPlayerControllerFactory
import com.apple.android.music.playback.model.MediaPlayerException
import com.apple.android.music.playback.model.PlayerQueueItem

/**
 * Owns [MediaPlayerController] create/release, music-user-token binding, and listener fan-out.
 */
internal class PlaybackSession(
  private val appContext: Context,
  private val mainHandler: Handler,
  private val onSongCacheCleared: () -> Unit,
) {
  @Volatile
  private var controller: MediaPlayerController? = null

  private val externalListeners = mutableSetOf<MediaPlayerController.Listener>()

  @Volatile
  private var boundMusicUserToken: String? = null

  var playbackErrorHandler: ((MediaPlayerException, String) -> Unit)? = null

  private val globalErrorListener =
    object : MediaPlayerController.Listener {
      override fun onPlaybackError(
        player: MediaPlayerController,
        error: MediaPlayerException,
      ) {
        Log.e(TAG, "playback error type=${error.type} code=${error.errorCode}", error)
        playbackErrorHandler?.invoke(error, "playback")
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

      override fun onPlaybackQueueItemsAdded(
        player: MediaPlayerController,
        queueInsertionType: Int,
        containerIndex: Int,
        itemCount: Int,
      ) {
      }

      override fun onPlaybackRepeatModeChanged(player: MediaPlayerController, mode: Int) {}

      override fun onPlaybackShuffleModeChanged(player: MediaPlayerController, mode: Int) {}
    }

  /** Drops the native player when the music user token changes (SDK caches credentials). */
  fun applyMusicUserToken(token: String?) {
    val trimmed = token?.trim()?.takeIf { it.isNotEmpty() } ?: return
    MusicKitAuthStorage.saveMusicUserToken(appContext, trimmed)
    if (trimmed != boundMusicUserToken) {
      releaseControllerSync()
    }
  }

  fun ensureController(): MediaPlayerController {
    AndroidDeveloperToken.requireStored(appContext)
    val token = MusicKitAuthStorage.getMusicUserToken(appContext)
    if (!token.isNullOrEmpty()) {
      return ensurePlaybackController(token)
    }
    val existing = controller
    if (existing != null) {
      return existing
    }
    return createController(null)
  }

  fun ensurePlaybackController(musicUserToken: String): MediaPlayerController {
    val existing = controller
    if (existing != null && boundMusicUserToken == musicUserToken) {
      return existing
    }
    releaseControllerSync()
    return createController(musicUserToken)
  }

  fun currentController(): MediaPlayerController? = controller

  fun addListener(listener: MediaPlayerController.Listener) {
    externalListeners.add(listener)
    val player = controller
    if (player != null) {
      player.addListener(listener)
      return
    }
    if (hasStoredDeveloperToken()) {
      ensureController().addListener(listener)
    }
  }

  /**
   * After [MusicKitAuthStorage.saveDeveloperToken], attach listeners registered before a JWT existed.
   */
  fun attachPendingListenersAfterDeveloperTokenStored() {
    if (!hasStoredDeveloperToken() || externalListeners.isEmpty()) return
    ensureController()
  }

  fun removeListener(listener: MediaPlayerController.Listener) {
    externalListeners.remove(listener)
    controller?.removeListener(listener)
  }

  fun hasStoredDeveloperToken(): Boolean =
    !MusicKitAuthStorage.getDeveloperToken(appContext).isNullOrBlank()

  fun warmUp() {
    AppleMusicNativeLoader.ensureLoaded()
  }

  /** Releases the native player and clears caches; keeps the outer singleton for observer re-attach. */
  fun releaseMediaPlayer() {
    if (Looper.myLooper() == Looper.getMainLooper()) {
      releaseControllerSync()
    } else {
      mainHandler.post { releaseControllerSync() }
    }
  }

  private fun createController(musicUserToken: String?): MediaPlayerController {
    AppleMusicNativeLoader.ensureLoaded()
    return MediaPlayerControllerFactory.createLocalController(
      appContext,
      MusicKitTokenProvider(appContext),
    ).also { player ->
      player.addListener(globalErrorListener)
      externalListeners.forEach { player.addListener(it) }
      controller = player
      boundMusicUserToken = musicUserToken
    }
  }

  private fun releaseControllerSync() {
    onSongCacheCleared()
    val player = controller ?: return
    controller = null
    boundMusicUserToken = null
    try {
      player.removeListener(globalErrorListener)
      externalListeners.forEach { player.removeListener(it) }
      player.release()
    } catch (error: Exception) {
      Log.w(TAG, "release playback controller failed", error)
    }
  }

  companion object {
    private const val TAG = "ExpoAppleMusic"
  }
}
