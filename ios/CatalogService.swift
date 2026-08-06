// CatalogService.swift
// Catalog façade: search + types. MusicKit get-by-id and REST relationships live in
// colocated extensions (CatalogService+MusicKitFetch / CatalogService+RestCatalog).
//
// Architecture: Catalog ID resolution and native/REST fallback live here (and in
// CatalogSearchStoreFactory). Do not add resolution branches in the Expo module,
// definition, or ExpoBridgeCatalog.

import Foundation
import MusicKit

@available(iOS 16.0, *)
final class CatalogService {

  enum CatalogServiceError: LocalizedError {
    case notFound(String)
    case configurationRequired(String)
    case unknownResourceType(String)

    var errorDescription: String? {
      switch self {
      case .notFound(let item):
        return "\(item) not found"
      case .configurationRequired(let message):
        return message
      case .unknownResourceType(let type):
        return "Unknown catalog resource type: \(type)"
      }
    }
  }

  // MARK: - Search

  struct SearchOptions {
    let limit: Int
    let offset: Int

    init(from dictionary: NSDictionary) {
      limit = dictionary["limit"] as? Int ?? 25
      offset = dictionary["offset"] as? Int ?? 0
    }

    init(limit: Int, offset: Int) {
      self.limit = limit
      self.offset = offset
    }
  }

  struct SearchResult {
    let songs: [[String: Any]]
    let albums: [[String: Any]]
    let artists: [[String: Any]]
    let playlists: [[String: Any]]
    let stations: [[String: Any]]
    let musicVideos: [[String: Any]]
  }

  struct ChartsResult {
    let songs: [[String: Any]]
    let albums: [[String: Any]]
    let playlists: [[String: Any]]
    let musicVideos: [[String: Any]]
  }

  func search(term: String, types: [String], options: SearchOptions) async throws -> SearchResult {
    try await CatalogSearchStoreFactory.search(term: term, types: types, options: options)
  }
}
