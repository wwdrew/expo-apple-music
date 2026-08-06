package expo.modules.applemusic.bridge

import expo.modules.applemusic.AppleMusicErrors
import expo.modules.applemusic.BridgeResponses
import expo.modules.applemusic.CatalogRestClient
import expo.modules.applemusic.PaginationOptions
import expo.modules.kotlin.functions.Coroutine
import expo.modules.kotlin.modules.ModuleDefinitionBuilder

internal fun ModuleDefinitionBuilder.registerCatalogBridge(
  catalog: () -> CatalogRestClient,
) {
  AsyncFunction("catalogSearch") Coroutine { term: String, types: List<String>, options: Map<String, Any?> ->
    val pagination = PaginationOptions.fromMap(options)
    BridgeResponses.catalogSearch(catalog().catalogSearch(term, types, pagination.limit, pagination.offset))
  }

  AsyncFunction("getCatalogSong") Coroutine { id: String ->
    catalog().getCatalogSong(id)
  }

  AsyncFunction("getCatalogAlbum") Coroutine { id: String ->
    catalog().getCatalogAlbum(id)
  }

  AsyncFunction("getCatalogArtist") Coroutine { id: String ->
    catalog().getCatalogArtist(id)
  }

  AsyncFunction("getCatalogPlaylist") Coroutine { id: String ->
    catalog().getCatalogPlaylist(id)
  }

  AsyncFunction("getCatalogStation") Coroutine { id: String ->
    catalog().getCatalogStation(id)
  }

  AsyncFunction("getCatalogMusicVideo") Coroutine { id: String ->
    catalog().getCatalogMusicVideo(id)
  }

  AsyncFunction("getCatalogAlbumTracks") Coroutine { albumId: String, options: Map<String, Any?> ->
    val pagination = PaginationOptions.fromMap(options)
    BridgeResponses.songs(catalog().getCatalogAlbumTracks(albumId, pagination.limit, pagination.offset))
  }

  AsyncFunction("getCatalogArtistAlbums") Coroutine { artistId: String, options: Map<String, Any?> ->
    val pagination = PaginationOptions.fromMap(options)
    BridgeResponses.albums(catalog().getCatalogArtistAlbums(artistId, pagination.limit, pagination.offset))
  }

  AsyncFunction("getCatalogPlaylistTracks") Coroutine { playlistId: String, options: Map<String, Any?> ->
    val pagination = PaginationOptions.fromMap(options)
    BridgeResponses.songs(catalog().getCatalogPlaylistTracks(playlistId, pagination.limit, pagination.offset))
  }

  AsyncFunction("getCatalogCharts") Coroutine { types: List<String>, options: Map<String, Any?> ->
    val pagination = PaginationOptions.fromMap(options)
    val genre = options["genre"] as? String
    val chart = options["chart"] as? String
    BridgeResponses.catalogCharts(
      catalog().getCatalogCharts(types, pagination.limit, pagination.offset, genre, chart),
    )
  }

  AsyncFunction("getCatalogResources") Coroutine { type: String, ids: List<String> ->
    val items = catalog().getCatalogResources(type, ids)
    when (type) {
      "songs" -> BridgeResponses.songs(items)
      "albums" -> BridgeResponses.albums(items)
      "artists" -> BridgeResponses.artists(items)
      "playlists" -> BridgeResponses.playlists(items)
      "stations" -> BridgeResponses.stations(items)
      "music-videos" -> BridgeResponses.musicVideos(items)
      else -> throw AppleMusicErrors.unknownMediaType(type)
    }
  }
}
