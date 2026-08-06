package expo.modules.applemusic

import java.io.FileNotFoundException

/**
 * Pure playback error message mapping (no MusicKit AAR / Expo deps) — JVM-testable.
 */
internal object PlaybackErrorMessages {
  fun forGenericFailure(error: Exception): String {
    val message = error.message.orEmpty()
    if (error is FileNotFoundException && message.contains("api.music.apple.com")) {
      return "Apple Music API rejected the request (often an expired session). Call Auth.authorize(developerToken) again."
    }
    return error.message ?: "Playback failed"
  }
}
