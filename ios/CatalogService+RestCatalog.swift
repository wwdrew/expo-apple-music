// CatalogService+RestCatalog.swift
// REST-only catalog gaps: relationships (tracks/albums), charts, and batch resources.

import Foundation

@available(iOS 16.0, *)
extension CatalogService {

  func getAlbumTracks(albumId: String, options: SearchOptions) async throws -> [[String: Any]] {
    try await getCatalogRelationship(
      path: "/albums/\(albumId)/tracks",
      options: options,
      typeContains: "song",
      mapper: RestJsonMapper.mapSong
    )
  }

  func getArtistAlbums(artistId: String, options: SearchOptions) async throws -> [[String: Any]] {
    try await getCatalogRelationship(
      path: "/artists/\(artistId)/albums",
      options: options,
      typeContains: "album",
      mapper: RestJsonMapper.mapAlbum
    )
  }

  func getPlaylistTracks(playlistId: String, options: SearchOptions) async throws -> [[String: Any]] {
    try await getCatalogRelationship(
      path: "/playlists/\(playlistId)/tracks",
      options: options,
      typeContains: "song",
      mapper: RestJsonMapper.mapSong
    )
  }

  func getCharts(
    types: [String],
    options: SearchOptions,
    genre: String?,
    chart: String?
  ) async throws -> ChartsResult {
    let storefront = StorefrontService.getCatalogStorefront()
    var query: [String: String] = [
      "types": types.isEmpty ? "songs,albums" : types.joined(separator: ","),
      "limit": "\(options.limit)",
      "offset": "\(options.offset)",
    ]
    if let genre, !genre.isEmpty { query["genre"] = genre }
    if let chart, !chart.isEmpty { query["chart"] = chart }

    let json = try await AppleMusicRestClient.get(
      path: "/v1/catalog/\(storefront)/charts",
      query: query
    )
    let results = json["results"] as? [String: Any] ?? [:]

    return ChartsResult(
      songs: parseChartsEntries(results: results, key: "songs", typeContains: "song", mapper: RestJsonMapper.mapSong),
      albums: parseChartsEntries(results: results, key: "albums", typeContains: "album", mapper: RestJsonMapper.mapAlbum),
      playlists: parseChartsEntries(
        results: results, key: "playlists", typeContains: "playlist", mapper: RestJsonMapper.mapPlaylist),
      musicVideos: parseChartsEntries(
        results: results, key: "music-videos", typeContains: "music-video", mapper: RestJsonMapper.mapMusicVideo)
    )
  }

  func getResources(type: String, ids: [String]) async throws -> [[String: Any]] {
    let trimmed = ids.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    if trimmed.isEmpty {
      return []
    }
    let storefront = StorefrontService.getCatalogStorefront()
    let path = "/v1/catalog/\(storefront)/\(type)"
    let json = try await AppleMusicRestClient.get(path: path, query: ["ids": trimmed.joined(separator: ",")])
    let data = try AppleMusicRestClient.parseDataArray(from: json)
    return data.compactMap { resource in
      mapCatalogResource(type: type, resource: resource)
    }
  }

  private func parseChartsEntries(
    results: [String: Any],
    key: String,
    typeContains: String,
    mapper: ([String: Any]) -> [String: Any]
  ) -> [[String: Any]] {
    guard let charts = results[key] as? [[String: Any]] else { return [] }
    var items: [[String: Any]] = []
    for chart in charts {
      guard let data = chart["data"] as? [[String: Any]] else { continue }
      for resource in data {
        let type = resource["type"] as? String ?? ""
        guard type.contains(typeContains) else { continue }
        items.append(mapper(resource))
      }
    }
    return items
  }

  private func getCatalogRelationship(
    path: String,
    options: SearchOptions,
    typeContains: String,
    mapper: ([String: Any]) -> [String: Any]
  ) async throws -> [[String: Any]] {
    let storefront = StorefrontService.getCatalogStorefront()
    let fullPath = "/v1/catalog/\(storefront)\(path)"
    let query = [
      "limit": "\(options.limit)",
      "offset": "\(options.offset)",
    ]
    let data = try await AppleMusicRestClient.getDataArray(path: fullPath, query: query)
    return data.compactMap { resource in
      let type = resource["type"] as? String ?? ""
      guard type.contains(typeContains) else { return nil }
      return mapper(resource)
    }
  }

  private func mapCatalogResource(type: String, resource: [String: Any]) -> [String: Any]? {
    let apiType = resource["type"] as? String ?? ""
    switch type {
    case "songs" where apiType.contains("song"):
      return RestJsonMapper.mapSong(resource)
    case "albums" where apiType.contains("album"):
      return RestJsonMapper.mapAlbum(resource)
    case "artists" where apiType.contains("artist"):
      return RestJsonMapper.mapArtist(resource)
    case "playlists" where apiType.contains("playlist"):
      return RestJsonMapper.mapPlaylist(resource)
    case "stations" where apiType.contains("station"):
      return RestJsonMapper.mapStation(resource)
    case "music-videos" where apiType.contains("music-video"):
      return RestJsonMapper.mapMusicVideo(resource)
    default:
      return nil
    }
  }
}
