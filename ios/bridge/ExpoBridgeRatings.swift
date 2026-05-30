import Foundation

@available(iOS 16.0, *)
enum ExpoBridgeRatings {
  static func getRating(
    service: RatingsService,
    musicUserToken: String,
    resourceType: String,
    id: String
  ) async throws -> [String: Any]? {
    try await AppleMusicBridgeError.rethrow {
      try await service.getRating(musicUserToken: musicUserToken, resourceType: resourceType, id: id)
    }
  }

  static func setRating(
    service: RatingsService,
    musicUserToken: String,
    resourceType: String,
    id: String,
    value: Int
  ) async throws -> [String: Any] {
    try await AppleMusicBridgeError.rethrow {
      try await service.setRating(
        musicUserToken: musicUserToken, resourceType: resourceType, id: id, value: value)
    }
  }

  static func clearRating(
    service: RatingsService,
    musicUserToken: String,
    resourceType: String,
    id: String
  ) async throws {
    try await AppleMusicBridgeError.rethrow {
      try await service.clearRating(
        musicUserToken: musicUserToken, resourceType: resourceType, id: id)
    }
  }

  static func addToFavorites(
    service: RatingsService,
    musicUserToken: String,
    resourceIds: [String: [String]]
  ) async throws {
    try await AppleMusicBridgeError.rethrow {
      try await service.addToFavorites(musicUserToken: musicUserToken, resourceIds: resourceIds)
    }
  }

  static func removeFromFavorites(
    service: RatingsService,
    musicUserToken: String,
    resourceIds: [String: [String]]
  ) async throws {
    try await AppleMusicBridgeError.rethrow {
      try await service.removeFromFavorites(musicUserToken: musicUserToken, resourceIds: resourceIds)
    }
  }
}
