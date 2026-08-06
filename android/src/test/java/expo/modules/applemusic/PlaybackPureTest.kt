package expo.modules.applemusic

import java.io.FileNotFoundException
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Pure playback helpers — no MusicKit AAR required. */
class PlaybackPureTest {
  @Test
  fun libraryIds_recognizesPrefixes() {
    assertTrue(LibraryIds.isLibraryId("i.abc"))
    assertTrue(LibraryIds.isLibraryId("l.abc"))
    assertTrue(LibraryIds.isLibraryId("p.abc"))
    assertFalse(LibraryIds.isLibraryId("1441164424"))
  }

  @Test
  fun mediaType_fromRaw() {
    assertEquals(PlaybackQueueRules.MediaType.SONG, PlaybackQueueRules.MediaType.from("song"))
    assertEquals(PlaybackQueueRules.MediaType.STATION, PlaybackQueueRules.MediaType.from("station"))
    assertNull(PlaybackQueueRules.MediaType.from("podcast"))
  }

  @Test
  fun stationUnsupportedMessage_isStable() {
    assertEquals(
      "Station playback is not supported on Android.",
      PlaybackQueueRules.STATION_UNSUPPORTED_ON_ANDROID,
    )
    assertFalse(PlaybackQueueRules.STATION_UNSUPPORTED_ON_ANDROID.contains("yet"))
  }

  @Test
  fun playbackErrorMessages_mapsExpiredSessionFileNotFound() {
    val error = FileNotFoundException("https://api.music.apple.com/v1/me/storefront")
    assertTrue(PlaybackErrorMessages.forGenericFailure(error).contains("expired session"))
  }

  @Test
  fun playbackErrorMessages_passesThroughOtherMessages() {
    assertEquals("boom", PlaybackErrorMessages.forGenericFailure(RuntimeException("boom")))
  }
}
