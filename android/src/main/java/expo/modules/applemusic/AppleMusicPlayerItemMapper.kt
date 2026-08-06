package expo.modules.applemusic

import com.apple.android.music.playback.model.PlayerMediaItem
import com.apple.android.music.playback.model.PlaybackState

/** Maps MusicKit playback AAR types to bridge dictionaries. */
internal object AppleMusicPlayerItemMapper {
  fun mapPlayerMediaItem(item: PlayerMediaItem): Map<String, Any?> =
    mapOf(
      "id" to item.subscriptionStoreId.orEmpty().ifEmpty { item.playbackStoreId },
      "title" to item.title.orEmpty(),
      "artistName" to item.artistName.orEmpty(),
      "artworkUrl" to (item.getArtworkUrl(200, 200) ?: ""),
      "duration" to (item.duration / 1000).toString(),
    )

  fun describePlaybackStatus(state: Int): String =
    when (state) {
      PlaybackState.PLAYING -> "playing"
      PlaybackState.PAUSED -> "paused"
      PlaybackState.STOPPED -> "stopped"
      else -> "unknown"
    }
}
