package expo.modules.applemusic

import com.apple.android.music.playback.controller.MediaPlayerController
import com.apple.android.music.playback.model.PlayerMediaItem

/** Maps native player state → bridge maps and caches the current song payload. */
internal class PlaybackStateSnapshot {
  private var cachedSongId: String? = null
  private var cachedSongInfo: Map<String, Any?>? = null

  fun clearSongCache() {
    cachedSongId = null
    cachedSongInfo = null
  }

  fun idlePlaybackState(): Map<String, Any?> =
    BridgeResponses.playbackState(
      playbackRate = 1.0,
      playbackStatus = "stopped",
      playbackTime = 0.0,
      currentSong = null,
    )

  fun currentState(
    hasDeveloperToken: Boolean,
    controller: MediaPlayerController?,
    ensureController: () -> MediaPlayerController,
  ): Map<String, Any?> {
    if (!hasDeveloperToken) {
      return idlePlaybackState()
    }
    val player = controller ?: ensureController()
    val playbackStatus = AppleMusicJsonMapper.describePlaybackStatus(player.playbackState)
    val playbackTime = player.currentPosition.coerceAtLeast(0) / 1000.0
    return BridgeResponses.playbackState(
      playbackRate = player.playbackRate.toDouble(),
      playbackStatus = playbackStatus,
      playbackTime = playbackTime,
      currentSong = fetchCurrentSongInfo(player),
    )
  }

  fun fetchCurrentSongInfo(player: MediaPlayerController?): Map<String, Any?>? {
    if (player == null) return null
    val item: PlayerMediaItem = player.currentItem?.item ?: run {
      clearSongCache()
      return null
    }

    val currentId =
      item.subscriptionStoreId?.takeIf { it.isNotEmpty() }
        ?: item.playbackStoreId.takeIf { it.isNotEmpty() }

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
}
