import Foundation

@available(iOS 16.0, *)
enum ExpoBridgeCatalog {
  static func getCatalogSong(service: CatalogService, id: String) async throws -> [String: Any] {
    try await AppleMusicBridgeError.rethrow {
      try await service.getSong(id: id)
    }
  }

  static func getCatalogAlbum(service: CatalogService, id: String) async throws -> [String: Any] {
    try await AppleMusicBridgeError.rethrow {
      try await service.getAlbum(id: id)
    }
  }

  static func getCatalogArtist(service: CatalogService, id: String) async throws -> [String: Any] {
    try await AppleMusicBridgeError.rethrow {
      try await service.getArtist(id: id)
    }
  }

  static func getCatalogPlaylist(service: CatalogService, id: String) async throws -> [String: Any] {
    try await AppleMusicBridgeError.rethrow {
      try await service.getPlaylist(id: id)
    }
  }

  static func getCatalogStation(service: CatalogService, id: String) async throws -> [String: Any] {
    try await AppleMusicBridgeError.rethrow {
      try await service.getStation(id: id)
    }
  }

  static func getCatalogMusicVideo(service: CatalogService, id: String) async throws -> [String: Any] {
    try await AppleMusicBridgeError.rethrow {
      try await service.getMusicVideo(id: id)
    }
  }

  static func catalogSearch(
    service: CatalogService,
    term: String,
    types: [String],
    options: NSDictionary
  ) async throws -> [String: Any] {
    try await AppleMusicBridgeError.rethrow {
      let pagination = BridgePagination(from: options)
      let searchOptions = CatalogService.SearchOptions(limit: pagination.limit, offset: pagination.offset)
      let result = try await service.search(term: term, types: types, options: searchOptions)
      return BridgeResponses.catalogSearch(result)
    }
  }

  static func getCatalogAlbumTracks(
    service: CatalogService,
    albumId: String,
    options: NSDictionary
  ) async throws -> [String: Any] {
    try await AppleMusicBridgeError.rethrow {
      let pagination = BridgePagination(from: options)
      let searchOptions = CatalogService.SearchOptions(limit: pagination.limit, offset: pagination.offset)
      let songs = try await service.getAlbumTracks(albumId: albumId, options: searchOptions)
      return BridgeResponses.songs(songs)
    }
  }

  static func getCatalogArtistAlbums(
    service: CatalogService,
    artistId: String,
    options: NSDictionary
  ) async throws -> [String: Any] {
    try await AppleMusicBridgeError.rethrow {
      let pagination = BridgePagination(from: options)
      let searchOptions = CatalogService.SearchOptions(limit: pagination.limit, offset: pagination.offset)
      let albums = try await service.getArtistAlbums(artistId: artistId, options: searchOptions)
      return BridgeResponses.albums(albums)
    }
  }

  static func getCatalogPlaylistTracks(
    service: CatalogService,
    playlistId: String,
    options: NSDictionary
  ) async throws -> [String: Any] {
    try await AppleMusicBridgeError.rethrow {
      let pagination = BridgePagination(from: options)
      let searchOptions = CatalogService.SearchOptions(limit: pagination.limit, offset: pagination.offset)
      let songs = try await service.getPlaylistTracks(playlistId: playlistId, options: searchOptions)
      return BridgeResponses.songs(songs)
    }
  }

  static func getCatalogCharts(
    service: CatalogService,
    types: [String],
    options: [String: Any]
  ) async throws -> [String: Any] {
    try await AppleMusicBridgeError.rethrow {
      let pagination = BridgePagination(from: options as NSDictionary)
      let searchOptions = CatalogService.SearchOptions(limit: pagination.limit, offset: pagination.offset)
      let genre = options["genre"] as? String
      let chart = options["chart"] as? String
      let result = try await service.getCharts(types: types, options: searchOptions, genre: genre, chart: chart)
      return BridgeResponses.catalogCharts(result)
    }
  }

  static func getCatalogResources(
    service: CatalogService,
    type: String,
    ids: [String]
  ) async throws -> [String: Any] {
    try await AppleMusicBridgeError.rethrow {
      let items = try await service.getResources(type: type, ids: ids)
      switch type {
      case "songs":
        return BridgeResponses.songs(items)
      case "albums":
        return BridgeResponses.albums(items)
      case "artists":
        return BridgeResponses.artists(items)
      case "playlists":
        return BridgeResponses.playlists(items)
      case "stations":
        return BridgeResponses.stations(items)
      case "music-videos":
        return BridgeResponses.musicVideos(items)
      default:
        throw CatalogService.CatalogServiceError.unknownResourceType(type)
      }
    }
  }
}
