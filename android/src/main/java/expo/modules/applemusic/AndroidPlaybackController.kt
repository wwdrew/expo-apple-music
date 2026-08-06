package expo.modules.applemusic

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.apple.android.music.playback.controller.MediaPlayerController
import com.apple.android.music.playback.model.MediaContainerType
import com.apple.android.music.playback.model.MediaItemType
import com.apple.android.music.playback.model.MediaPlayerException
import com.apple.android.music.playback.queue.CatalogPlaybackQueueItemProvider
import com.apple.android.music.playback.queue.PlaybackQueueItemProvider
import expo.modules.kotlin.exception.CodedException

/**
 * Playback façade: session lifecycle, queue prepare, transport commands, and state snapshots.
 * Heavy lifting lives in [PlaybackSession], [PlaybackStateSnapshot], [PlaybackQueuePrepare],
 * and [PlaybackErrorMapper].
 */
internal class AndroidPlaybackController private constructor(
  context: Context,
) {
  private val appContext = context.applicationContext
  private val mainHandler = Handler(Looper.getMainLooper())
  private val stateSnapshot = PlaybackStateSnapshot()
  private val session =
    PlaybackSession(appContext, mainHandler, onSongCacheCleared = stateSnapshot::clearSongCache)

  var playbackErrorHandler: ((MediaPlayerException, String) -> Unit)?
    get() = session.playbackErrorHandler
    set(value) {
      session.playbackErrorHandler = value
    }

  internal fun applyMusicUserToken(token: String?) = session.applyMusicUserToken(token)

  fun addListener(listener: MediaPlayerController.Listener) = session.addListener(listener)

  internal fun attachPendingListenersAfterDeveloperTokenStored() =
    session.attachPendingListenersAfterDeveloperTokenStored()

  fun removeListener(listener: MediaPlayerController.Listener) = session.removeListener(listener)

  /** API parity with iOS `configurePlayer`; playback focus is handled by [MediaPlayerController]. */
  fun configurePlayer(options: Map<String, Any?>): Map<String, Any?> {
    val payload = linkedMapOf<String, Any?>(
      "playerType" to "application",
      "audioSession" to mapOf(
        "category" to "playback",
        "mode" to "default",
        "options" to emptyList<String>(),
        "setActive" to true,
      ),
    )
    payload.putAll(options)
    // Stubs do not implement AVAudioSession mixing — never claim otherwise.
    payload["mixWithOthers"] = false
    if (payload["playerType"] == null) {
      payload["playerType"] = "application"
    }
    return payload
  }

  suspend fun prepareQueue(provider: PlaybackQueueItemProvider, musicUserToken: String? = null) {
    PlaybackQueuePrepare.prepare(appContext, mainHandler, session, provider, musicUserToken)
  }

  fun play() {
    mainHandler.post { session.ensureController().play() }
  }

  fun pause() {
    mainHandler.post { session.ensureController().pause() }
  }

  fun togglePlayback() {
    mainHandler.post {
      val player = session.ensureController()
      when (player.playbackState) {
        com.apple.android.music.playback.model.PlaybackState.PLAYING -> player.pause()
        else -> player.play()
      }
    }
  }

  fun skipToNext() {
    mainHandler.post { session.ensureController().skipToNextItem() }
  }

  fun skipToPrevious() {
    mainHandler.post { session.ensureController().skipToPreviousItem() }
  }

  fun restartCurrentEntry(onComplete: ((Double) -> Unit)? = null) {
    mainHandler.post {
      session.ensureController().seekToPosition(0)
      onComplete?.invoke(0.0)
    }
  }

  fun seekToTime(seconds: Double, onComplete: ((Double) -> Unit)? = null) {
    mainHandler.post {
      val player = session.ensureController()
      player.seekToPosition((seconds * 1000).toLong())
      val actual = player.currentPosition.coerceAtLeast(0) / 1000.0
      onComplete?.invoke(actual)
    }
  }

  fun buildSongProvider(vararg catalogIds: String, startIndex: Int = 0): PlaybackQueueItemProvider {
    val ids = catalogIds.map { it.trim() }.filter { it.isNotEmpty() }.toTypedArray()
    if (ids.isEmpty()) {
      throw AppleMusicErrors.apiError("No catalog song ids for playback queue")
    }
    return CatalogPlaybackQueueItemProvider.Builder()
      .items(MediaItemType.SONG, *ids)
      .apply {
        if (startIndex > 0) startItemIndex(startIndex)
      }
      .build()
  }

  fun buildAlbumProvider(catalogId: String): PlaybackQueueItemProvider =
    CatalogPlaybackQueueItemProvider.Builder()
      .containers(MediaContainerType.ALBUM, catalogId.trim())
      .build()

  fun buildPlaylistProvider(catalogId: String): PlaybackQueueItemProvider =
    CatalogPlaybackQueueItemProvider.Builder()
      .containers(MediaContainerType.PLAYLIST, catalogId.trim())
      .build()

  fun warmUp() = session.warmUp()

  internal fun releaseMediaPlayer() = session.releaseMediaPlayer()

  fun clearSongCache() = stateSnapshot.clearSongCache()

  fun currentState(): Map<String, Any?> =
    stateSnapshot.currentState(
      hasDeveloperToken = session.hasStoredDeveloperToken(),
      controller = session.currentController(),
      ensureController = session::ensureController,
    )

  fun fetchCurrentSongInfo(): Map<String, Any?>? =
    stateSnapshot.fetchCurrentSongInfo(session.currentController())

  companion object {
    private const val TAG = "ExpoAppleMusic"

    @Volatile
    private var instance: AndroidPlaybackController? = null

    fun getInstance(context: Context): AndroidPlaybackController =
      instance
        ?: synchronized(this) {
          instance ?: AndroidPlaybackController(context.applicationContext).also { instance = it }
        }

    fun warmUp(context: Context) {
      try {
        getInstance(context).warmUp()
      } catch (error: Exception) {
        Log.w(TAG, "playback warmUp failed", error)
      }
    }

    fun resetInstance() {
      synchronized(this) {
        instance?.releaseMediaPlayer()
      }
    }

    fun mapPlaybackException(error: Exception): CodedException = PlaybackErrorMapper.map(error)
  }
}
