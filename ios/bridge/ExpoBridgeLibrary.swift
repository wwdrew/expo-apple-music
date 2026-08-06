import Foundation

@available(iOS 16.0, *)
enum ExpoBridgeLibrary {
  static func getUserPlaylists(
    service: LibraryService,
    musicUserToken: String,
    options: NSDictionary
  ) async throws -> [String: Any] {
    try await ExpoBridge.asyncBridge {
      let pagination = BridgePagination(from: options)
      let playlists = try await service.getPlaylists(musicUserToken: musicUserToken, options: pagination)
      return BridgeResponses.playlists(playlists)
    }
  }

  static func getLibrarySongs(
    service: LibraryService,
    musicUserToken: String,
    options: NSDictionary
  ) async throws -> [String: Any] {
    try await ExpoBridge.asyncBridge {
      let pagination = BridgePagination(from: options)
      let songs = try await service.getSongs(musicUserToken: musicUserToken, options: pagination)
      return BridgeResponses.songs(songs)
    }
  }

  static func getPlaylistSongs(
    service: LibraryService,
    musicUserToken: String,
    playlistId: String
  ) async throws -> [String: Any] {
    try await ExpoBridge.asyncBridge {
      let songs = try await service.getPlaylistSongs(musicUserToken: musicUserToken, playlistId: playlistId)
      return BridgeResponses.songs(songs)
    }
  }

  static func getLibraryArtists(
    service: LibraryService,
    musicUserToken: String,
    options: NSDictionary
  ) async throws -> [String: Any] {
    try await ExpoBridge.asyncBridge {
      let pagination = BridgePagination(from: options)
      let artists = try await service.getArtists(musicUserToken: musicUserToken, options: pagination)
      return BridgeResponses.artists(artists)
    }
  }

  static func getLibraryAlbums(
    service: LibraryService,
    musicUserToken: String,
    options: NSDictionary
  ) async throws -> [String: Any] {
    try await ExpoBridge.asyncBridge {
      let pagination = BridgePagination(from: options)
      let albums = try await service.getAlbums(musicUserToken: musicUserToken, options: pagination)
      return BridgeResponses.albums(albums)
    }
  }

  static func getLibraryMusicVideos(
    service: LibraryService,
    musicUserToken: String,
    options: NSDictionary
  ) async throws -> [String: Any] {
    try await ExpoBridge.asyncBridge {
      let pagination = BridgePagination(from: options)
      let musicVideos = try await service.getMusicVideos(musicUserToken: musicUserToken, options: pagination)
      return BridgeResponses.musicVideos(musicVideos)
    }
  }

  static func librarySearch(
    service: LibraryService,
    musicUserToken: String,
    term: String,
    types: [String],
    options: NSDictionary
  ) async throws -> [String: Any] {
    try await ExpoBridge.asyncBridge {
      let pagination = BridgePagination(from: options)
      let result = try await service.search(
        musicUserToken: musicUserToken,
        term: term,
        types: types,
        options: pagination)
      return BridgeResponses.librarySearch(result)
    }
  }
}
