import Foundation

@available(iOS 16.0, *)
enum ExpoBridgeRecommendations {
  static func getRecommendations(
    service: RecommendationsService,
    musicUserToken: String,
    ids: [String]?
  ) async throws -> [String: Any] {
    try await ExpoBridge.asyncBridge {
      let recommendations = try await service.getRecommendations(
        musicUserToken: musicUserToken,
        ids: ids)
      return BridgeResponses.recommendations(recommendations)
    }
  }

  static func getReplay(
    service: RecommendationsService,
    musicUserToken: String,
    year: Int?
  ) async throws -> [String: Any] {
    try await ExpoBridge.asyncBridge {
      let summaries = try await service.getReplay(musicUserToken: musicUserToken, year: year)
      return BridgeResponses.replaySummaries(summaries)
    }
  }
}
