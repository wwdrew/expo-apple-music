package expo.modules.applemusic

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.apple.android.music.playback.controller.MediaPlayerController
import com.apple.android.music.playback.controller.MediaPlayerControllerFactory
import com.apple.android.music.playback.model.MediaContainerType
import com.apple.android.music.playback.model.MediaItemType
import com.apple.android.music.playback.model.MediaPlayerException
import com.apple.android.music.playback.model.PlayerMediaItem
import com.apple.android.music.playback.model.PlayerQueueItem
import com.apple.android.music.playback.queue.CatalogPlaybackQueueItemProvider
import com.apple.android.music.playback.queue.PlaybackQueueInsertionType
import com.apple.android.music.playback.queue.PlaybackQueueItemProvider
import expo.modules.kotlin.exception.CodedException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

internal class AndroidPlaybackController private constructor(
  context: Context,
) {
  private val appContext = context.applicationContext
  private val mainHandler = Handler(Looper.getMainLooper())

  @Volatile
  private var controller: MediaPlayerController? = null

  private val externalListeners =
    mutableSetOf<MediaPlayerController.Listener>()

  @Volatile
  private var boundMusicUserToken: String? = null

  /** Drops the native player when the music user token changes (SDK caches credentials). */
  internal fun applyMusicUserToken(token: String?) {
    val trimmed = token?.trim()?.takeIf { it.isNotEmpty() } ?: return
    MusicKitAuthStorage.saveMusicUserToken(appContext, trimmed)
    if (trimmed != boundMusicUserToken) {
      releaseControllerSync()
    }
  }

  private fun ensureController(): MediaPlayerController {
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

  private fun ensurePlaybackController(musicUserToken: String): MediaPlayerController {
    val existing = controller
    if (existing != null && boundMusicUserToken == musicUserToken) {
      return existing
    }
    releaseControllerSync()
    return createController(musicUserToken)
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
    clearSongCache()
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

  private var cachedSongId: String? = null
  private var cachedSongInfo: Map<String, Any?>? = null

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
  internal fun attachPendingListenersAfterDeveloperTokenStored() {
    if (!hasStoredDeveloperToken() || externalListeners.isEmpty()) return
    ensureController()
  }

  private fun hasStoredDeveloperToken(): Boolean =
    !MusicKitAuthStorage.getDeveloperToken(appContext).isNullOrBlank()

  private fun idlePlaybackState(): Map<String, Any?> =
    mapOf(
      "playbackRate" to 1.0,
      "playbackStatus" to "stopped",
      "playbackTime" to 0.0,
    )

  fun removeListener(listener: MediaPlayerController.Listener) {
    externalListeners.remove(listener)
    controller?.removeListener(listener)
  }

  /** API parity with iOS `configureAudioSession`; playback focus is handled by [MediaPlayerController]. */
  fun configurePlayer(options: Map<String, Any?>): Map<String, Any?> =
    mapOf("mixWithOthers" to false) + options

  /**
   * [MediaPlayerController.prepare] loads queue items asynchronously — wait for
   * [onPlaybackQueueItemsAdded] before returning to JS.
   */
  suspend fun prepareQueue(provider: PlaybackQueueItemProvider, musicUserToken: String? = null) {
    AndroidDeveloperToken.requireStored(appContext)
    val stack = AppleMusicRestStack.create(appContext)
    val effectiveToken = resolvePlaybackMusicUserToken(appContext, musicUserToken)
    stack.storefront.requireUserStorefront(effectiveToken)
    withContext(Dispatchers.Main) {
      val player = ensurePlaybackController(effectiveToken)
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
              continuation.resumeWithException(mapPlaybackException(error))
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
            continuation.resumeWithException(mapPlaybackException(error))
          }
        }
      }
    }
  }

  fun play() {
    mainHandler.post { ensureController().play() }
  }

  fun pause() {
    mainHandler.post { ensureController().pause() }
  }

  fun togglePlayback() {
    mainHandler.post {
      val player = ensureController()
      when (player.playbackState) {
        com.apple.android.music.playback.model.PlaybackState.PLAYING -> player.pause()
        else -> player.play()
      }
    }
  }

  fun skipToNext() {
    mainHandler.post { ensureController().skipToNextItem() }
  }

  fun skipToPrevious() {
    mainHandler.post { ensureController().skipToPreviousItem() }
  }

  fun restartCurrentEntry(onComplete: ((Double) -> Unit)? = null) {
    mainHandler.post {
      ensureController().seekToPosition(0)
      onComplete?.invoke(0.0)
    }
  }

  fun seekToTime(seconds: Double, onComplete: ((Double) -> Unit)? = null) {
    mainHandler.post {
      val player = ensureController()
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

  fun warmUp() {
    AppleMusicNativeLoader.ensureLoaded()
  }

  /** Releases the native player and clears caches; keeps this singleton for observer re-attach. */
  internal fun releaseMediaPlayer() {
    if (Looper.myLooper() == Looper.getMainLooper()) {
      releaseControllerSync()
    } else {
      mainHandler.post { releaseControllerSync() }
    }
  }

  fun clearSongCache() {
    cachedSongId = null
    cachedSongInfo = null
  }

  fun currentState(): Map<String, Any?> {
    if (!hasStoredDeveloperToken()) {
      return idlePlaybackState()
    }
    val player = controller ?: ensureController()
    val playbackStatus = AppleMusicJsonMapper.describePlaybackStatus(player.playbackState)
    val playbackTime = player.currentPosition.coerceAtLeast(0) / 1000.0
    return buildMap {
      put("playbackRate", player.playbackRate)
      put("playbackStatus", playbackStatus)
      put("playbackTime", playbackTime)
      fetchCurrentSongInfo()?.let { put("currentSong", it) }
    }
  }

  fun fetchCurrentSongInfo(): Map<String, Any?>? {
    val player = controller ?: return null
    val item: PlayerMediaItem = player.currentItem?.item ?: return run {
      clearSongCache()
      null
    }

    val currentId =
      item.subscriptionStoreId?.takeIf { it.isNotEmpty() }
        ?: item.a()?.takeIf { !it.isNullOrEmpty() }

    if (currentId == null) {
      val fallback = AppleMusicJsonMapper.mapPlayerMediaItem(item)
      return fallback.takeIf { (it["title"] as? String)?.isNotEmpty() == true } ?: cachedSongInfo
    }

    if (currentId == cachedSongId && cachedSongInfo != null) {
      return cachedSongInfo
    }

    val songInfo = AppleMusicJsonMapper.mapPlayerMediaItem(item)
    cachedSongId = currentId
    cachedSongInfo = songInfo
    return songInfo
  }


  companion object {
    private const val TAG = "ExpoAppleMusic"
    private const val PREPARE_TIMEOUT_MS = 20_000L

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

    fun mapPlaybackException(error: Exception): CodedException =
      when (error) {
        is CodedException -> error
        is MediaPlayerException ->
          CodedException(
            AppleMusicErrorCodes.PLAYBACK_ERROR,
            error.message ?: "Media playback failed (type=${error.type}, code=${error.errorCode})",
            null,
          )
        else -> {
          val message = error.message.orEmpty()
          val hint =
            if (error is java.io.FileNotFoundException && message.contains("api.music.apple.com")) {
              "Apple Music API rejected the request (often an expired session). Call Auth.authorize(developerToken) again."
            } else {
              error.message ?: "Playback failed"
            }
          CodedException(AppleMusicErrorCodes.PLAYBACK_ERROR, hint, null)
        }
      }
  }
}
