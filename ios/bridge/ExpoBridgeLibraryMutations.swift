import Foundation

@available(iOS 16.0, *)
enum ExpoBridgeLibraryMutations {
  static func addToLibrary(
    service: LibraryMutationsService,
    musicUserToken: String,
    resourceIds: [String: [String]]
  ) async throws {
    try await AppleMusicBridgeError.rethrow {
      try await service.addToLibrary(musicUserToken: musicUserToken, resourceIds: resourceIds)
    }
  }

  static func createLibraryPlaylist(
    service: LibraryMutationsService,
    musicUserToken: String,
    options: [String: Any]
  ) async throws -> [String: Any] {
    try await AppleMusicBridgeError.rethrow {
      let name = options["name"] as? String ?? ""
      let description = options["description"] as? String
      let isPublic = options["isPublic"] as? Bool ?? false
      let tracks = options["tracks"] as? [[String: String]]
      return try await service.createPlaylist(
        musicUserToken: musicUserToken,
        name: name,
        description: description,
        isPublic: isPublic,
        tracks: tracks
      )
    }
  }

  static func addTracksToLibraryPlaylist(
    service: LibraryMutationsService,
    musicUserToken: String,
    playlistId: String,
    tracks: [[String: String]]
  ) async throws {
    try await AppleMusicBridgeError.rethrow {
      try await service.addTracksToPlaylist(
        musicUserToken: musicUserToken,
        playlistId: playlistId,
        tracks: tracks
      )
    }
  }
}
