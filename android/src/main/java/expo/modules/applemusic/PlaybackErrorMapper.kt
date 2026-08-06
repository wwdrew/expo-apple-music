package expo.modules.applemusic

import com.apple.android.music.playback.model.MediaPlayerException
import expo.modules.kotlin.exception.CodedException

/** Maps native playback failures to Expo [CodedException] bridge errors. */
internal object PlaybackErrorMapper {
  fun map(error: Exception): CodedException =
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
        val mappedMessage =
          if (error is java.io.FileNotFoundException && message.contains("api.music.apple.com")) {
            "Apple Music API rejected the request (often an expired session). Call Auth.authorize(developerToken) again."
          } else {
            error.message ?: "Playback failed"
          }
        CodedException(AppleMusicErrorCodes.PLAYBACK_ERROR, mappedMessage, error)
      }
    }
}
