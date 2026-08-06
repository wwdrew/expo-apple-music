package expo.modules.applemusic

/**
 * Pure playback queue rules (no MusicKit AAR / Expo deps) — JVM-testable in bridge-contract.
 */
internal object PlaybackQueueRules {
  enum class MediaType(val raw: String) {
    SONG("song"),
    ALBUM("album"),
    PLAYLIST("playlist"),
    STATION("station"),
    ;

    companion object {
      fun from(raw: String): MediaType? = entries.find { it.raw == raw }
    }
  }

  const val LIBRARY_QUEUE_REQUIRES_TOKEN =
    "Library queue requires a music user token. Use Player.playLibrarySong or playLibraryPlaylist."

  const val STATION_UNSUPPORTED_ON_ANDROID =
    "Station playback is not supported on Android yet."
}
