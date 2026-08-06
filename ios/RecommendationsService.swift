// RecommendationsService.swift
// Personal recommendations (MusicKit when possible) and Replay via Apple Music REST.

import Foundation
import MusicKit

@available(iOS 16.0, *)
final class RecommendationsService {

  /// When `ids` is nil/empty, use MusicKit `MusicPersonalRecommendationsRequest`.
  /// When `ids` is present, keep REST (`GET /v1/me/recommendations?ids=`).
  func getRecommendations(musicUserToken: String, ids: [String]?) async throws -> [[String: Any]] {
    if let ids, !ids.isEmpty {
      return try await getRecommendationsRest(musicUserToken: musicUserToken, ids: ids)
    }
    return try await getRecommendationsNative()
  }

  func getReplay(musicUserToken: String, year: Int?) async throws -> [[String: Any]] {
    var query: [String: String] = [:]
    if let year {
      query["filter[year]"] = "\(year)"
    }
    let data = try await AppleMusicRestClient.getDataArray(
      path: "/v1/me/music-summaries",
      musicUserToken: musicUserToken,
      query: query
    )
    return data.map(RestJsonMapper.mapReplaySummary)
  }

  private func getRecommendationsNative() async throws -> [[String: Any]] {
    let request = MusicPersonalRecommendationsRequest()
    let response = try await request.response()
    return response.recommendations.map(MusicItemMapper.map)
  }

  private func getRecommendationsRest(musicUserToken: String, ids: [String]) async throws -> [[String: Any]] {
    let data = try await AppleMusicRestClient.getDataArray(
      path: "/v1/me/recommendations",
      musicUserToken: musicUserToken,
      query: ["ids": ids.joined(separator: ",")]
    )
    return data.map(RestJsonMapper.mapRecommendation)
  }
}
