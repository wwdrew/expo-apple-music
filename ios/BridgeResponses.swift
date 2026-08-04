import Foundation

/// Standard bridge response envelopes (keys match Android and TypeScript).
enum BridgeResponses {
  static func storefront(id: String) -> [String: Any] {
    ["id": id]
  }

  static func catalogSearch(_ result: CatalogService.SearchResult) -> [String: Any] {
    [
      "songs": result.songs,
      "albums": result.albums,
      "artists": result.artists,
      "playlists": result.playlists,
      "stations": result.stations,
      "musicVideos": result.musicVideos,
    ]
  }

  static func catalogCharts(_ result: CatalogService.ChartsResult) -> [String: Any] {
    [
      "songs": result.songs,
      "albums": result.albums,
      "playlists": result.playlists,
      "musicVideos": result.musicVideos,
    ]
  }

  static func songs(_ items: [[String: Any]]) -> [String: Any] {
    ["songs": items]
  }

  static func albums(_ items: [[String: Any]]) -> [String: Any] {
    ["albums": items]
  }

  static func artists(_ items: [[String: Any]]) -> [String: Any] {
    ["artists": items]
  }

  static func playlists(_ items: [[String: Any]]) -> [String: Any] {
    ["playlists": items]
  }

  static func musicVideos(_ items: [[String: Any]]) -> [String: Any] {
    ["musicVideos": items]
  }

  static func librarySearch(_ result: LibraryService.LibrarySearchResult) -> [String: Any] {
    [
      "songs": result.songs,
      "albums": result.albums,
      "artists": result.artists,
      "playlists": result.playlists,
      "musicVideos": result.musicVideos,
    ]
  }

  static func stations(_ items: [[String: Any]]) -> [String: Any] {
    ["stations": items]
  }

  static func recentlyPlayedResources(_ items: [[String: Any]]) -> [String: Any] {
    ["recentlyPlayedItems": items]
  }

  static func recentItems(_ items: [[String: Any]]) -> [String: Any] {
    ["items": items]
  }

  static func recommendations(_ items: [[String: Any]]) -> [String: Any] {
    ["recommendations": items]
  }

  static func replaySummaries(_ items: [[String: Any]]) -> [String: Any] {
    ["summaries": items]
  }

  static func configurePlayer(options: [String: Any]) -> [String: Any] {
    ["mixWithOthers": false].merging(options) { _, latest in latest }
  }
}
