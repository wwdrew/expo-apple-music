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
        CodedException(
          AppleMusicErrorCodes.PLAYBACK_ERROR,
          PlaybackErrorMessages.forGenericFailure(error),
          error,
        )
      }
    }
}
