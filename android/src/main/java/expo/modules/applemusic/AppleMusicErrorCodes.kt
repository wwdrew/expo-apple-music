package expo.modules.applemusic

/**
 * Bridge rejection codes — keep in sync with [src/constants/apple-music-error-codes.ts]
 * and [docs/ERROR_CODES.md].
 */
internal object AppleMusicErrorCodes {
  const val ERROR = "ERROR"
  const val PERMISSION_DENIED = "permissionDenied"
  const val MISSING_DEVELOPER_TOKEN = "MISSING_DEVELOPER_TOKEN"
  const val MISSING_MUSIC_USER_TOKEN = "MISSING_MUSIC_USER_TOKEN"
  const val PLAYBACK_ERROR = "PLAYBACK_ERROR"
  /** Capability permanently unavailable on this platform (e.g. Android station queue). */
  const val UNSUPPORTED_PLATFORM = "UNSUPPORTED_PLATFORM"
}
