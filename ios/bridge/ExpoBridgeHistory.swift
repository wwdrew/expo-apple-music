import Foundation

@available(iOS 16.0, *)
enum ExpoBridgeHistory {
  static func getRecentlyPlayedResources(
    service: HistoryService,
    musicUserToken: String
  ) async throws -> [String: Any] {
    try await ExpoBridge.asyncBridge {
      let tracks = try await service.getRecentlyPlayedResources(musicUserToken: musicUserToken)
      return BridgeResponses.recentlyPlayedResources(tracks)
    }
  }

  static func getRecentlyPlayedTracks(
    service: HistoryService,
    musicUserToken: String,
    options: NSDictionary
  ) async throws -> [String: Any] {
    try await ExpoBridge.asyncBridge {
      let pagination = BridgePagination(from: options)
      let songs = try await service.getRecentlyPlayedTracks(
        musicUserToken: musicUserToken,
        options: pagination)
      return BridgeResponses.songs(songs)
    }
  }

  static func getHeavyRotation(
    service: HistoryService,
    musicUserToken: String,
    options: NSDictionary
  ) async throws -> [String: Any] {
    try await ExpoBridge.asyncBridge {
      let pagination = BridgePagination(from: options)
      let items = try await service.getHeavyRotation(
        musicUserToken: musicUserToken,
        limit: pagination.limit)
      return BridgeResponses.recentItems(items)
    }
  }

  static func getRecentlyPlayedStations(
    service: HistoryService,
    musicUserToken: String,
    options: NSDictionary
  ) async throws -> [String: Any] {
    try await ExpoBridge.asyncBridge {
      let pagination = BridgePagination(from: options)
      let stations = try await service.getRecentlyPlayedStations(
        musicUserToken: musicUserToken,
        limit: pagination.limit)
      return BridgeResponses.stations(stations)
    }
  }

  static func getRecentlyAdded(
    service: HistoryService,
    musicUserToken: String,
    options: NSDictionary
  ) async throws -> [String: Any] {
    try await ExpoBridge.asyncBridge {
      let pagination = BridgePagination(from: options)
      let items = try await service.getRecentlyAdded(
        musicUserToken: musicUserToken,
        limit: pagination.limit,
        offset: pagination.offset)
      return BridgeResponses.recentItems(items)
    }
  }
}
