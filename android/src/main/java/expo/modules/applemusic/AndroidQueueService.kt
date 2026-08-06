package expo.modules.applemusic

import android.content.Context

internal class AndroidQueueService(
  context: Context,
  private val playback: AndroidPlaybackController,
  private val library: LibraryRestClient,
) {
  constructor(context: Context, playback: AndroidPlaybackController) : this(
    context,
    playback,
    AppleMusicRestStack.create(context).library,
  )

  suspend fun setQueue(itemId: String, type: String) {
    val mediaType =
      PlaybackQueueRules.MediaType.from(type) ?: throw AppleMusicErrors.unknownMediaType(type)

    if (LibraryIds.isLibraryId(itemId)) {
      throw AppleMusicErrors.apiError(PlaybackQueueRules.LIBRARY_QUEUE_REQUIRES_TOKEN)
    } else {
      setCatalogQueue(itemId, mediaType)
    }
  }

  private suspend fun setCatalogQueue(itemId: String, type: PlaybackQueueRules.MediaType) {
    val provider =
      when (type) {
        PlaybackQueueRules.MediaType.SONG -> playback.buildSongProvider(itemId)
        PlaybackQueueRules.MediaType.ALBUM -> playback.buildAlbumProvider(itemId)
        PlaybackQueueRules.MediaType.PLAYLIST -> playback.buildPlaylistProvider(itemId)
        PlaybackQueueRules.MediaType.STATION ->
          throw AppleMusicErrors.apiError(PlaybackQueueRules.STATION_UNSUPPORTED_ON_ANDROID)
      }
    playback.clearSongCache()
    playback.prepareQueue(provider)
  }

  suspend fun playLibrarySong(musicUserToken: String, songId: String) {
    val catalogId = library.resolveCatalogPlaybackId(musicUserToken, songId, "song")
    playback.clearSongCache()
    playback.prepareQueue(playback.buildSongProvider(catalogId), musicUserToken)
  }

  suspend fun playLibraryPlaylist(musicUserToken: String, playlistId: String, startingAt: Int) {
    val catalogIds = library.resolveLibrarySongCatalogIds(musicUserToken, playlistId)
    if (catalogIds.isEmpty()) {
      throw AppleMusicErrors.noSongsInPlaylist()
    }
    val startIndex =
      when {
        startingAt == -1 -> 0
        startingAt in catalogIds.indices -> startingAt
        else -> 0
      }
    playback.clearSongCache()
    playback.prepareQueue(
      playback.buildSongProvider(*catalogIds.toTypedArray(), startIndex = startIndex),
      musicUserToken,
    )
  }
}
