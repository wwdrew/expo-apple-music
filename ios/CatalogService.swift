// CatalogService.swift
// Handles Apple Music catalog search and item fetching.
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

  func search(term: String, types: [String], options: SearchOptions) async throws -> SearchResult {
    try await CatalogSearchStoreFactory.search(term: term, types: types, options: options)
  }

  // MARK: - Fetch Single Items

  func getSong(id: String) async throws -> [String: Any] {
    guard let song = try await fetchSong(id: MusicItemID(id)) else {
      throw CatalogServiceError.notFound("Song")
    }
    return MusicItemMapper.map(song)
  }

  func getAlbum(id: String) async throws -> [String: Any] {
    guard let album = try await fetchAlbum(id: MusicItemID(id)) else {
      throw CatalogServiceError.notFound("Album")
    }
    return MusicItemMapper.map(album)
  }

  func getArtist(id: String) async throws -> [String: Any] {
    guard let artist = try await fetchArtist(id: MusicItemID(id)) else {
      throw CatalogServiceError.notFound("Artist")
    }
    return MusicItemMapper.map(artist)
  }

  func getPlaylist(id: String) async throws -> [String: Any] {
    guard let playlist = try await fetchPlaylist(id: MusicItemID(id)) else {
      throw CatalogServiceError.notFound("Playlist")
    }
    return MusicItemMapper.map(playlist)
  }

  func getStation(id: String) async throws -> [String: Any] {
    guard let station = try await fetchStation(id: MusicItemID(id)) else {
      throw CatalogServiceError.notFound("Station")
    }
    return MusicItemMapper.map(station)
  }

  func getMusicVideo(id: String) async throws -> [String: Any] {
    guard let musicVideo = try await fetchMusicVideo(id: MusicItemID(id)) else {
      throw CatalogServiceError.notFound("Music video")
    }
    return MusicItemMapper.map(musicVideo)
  }

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

  struct ChartsResult {
    let songs: [[String: Any]]
    let albums: [[String: Any]]
    let playlists: [[String: Any]]
    let musicVideos: [[String: Any]]
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

  func fetchSong(id: MusicItemID) async throws -> Song? {
    if let song = try await musicKitFetchSong(id: id) {
      return song
    }
    guard let resource = try await restCatalogSongResource(id: id.rawValue) else {
      return nil
    }
    for candidate in RestJsonMapper.catalogSongLookupIds(primaryId: id.rawValue, resource: resource) {
      if candidate == id.rawValue { continue }
      if let song = try await musicKitFetchSong(id: MusicItemID(candidate)) {
        return song
      }
    }
    return nil
  }

  private func musicKitFetchSong(id: MusicItemID) async throws -> Song? {
    let request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: id)
    let response = try await request.response()
    return response.items.first
  }

  /// REST catalog song resource — used when MusicKit lookup by playback id misses (e.g. after REST search).
  private func restCatalogSongResource(id: String) async throws -> [String: Any]? {
    let storefront = StorefrontService.getCatalogStorefront()
    let path = "/v1/catalog/\(storefront)/songs/\(id)"
    do {
      let json = try await AppleMusicRestClient.get(path: path)
      guard let data = json["data"] as? [[String: Any]], let resource = data.first else {
        return nil
      }
      return resource
    } catch {
      return nil
    }
  }

  func fetchAlbum(id: MusicItemID) async throws -> Album? {
    let request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: id)
    let response = try await request.response()
    return response.items.first
  }

  func fetchArtist(id: MusicItemID) async throws -> Artist? {
    let request = MusicCatalogResourceRequest<Artist>(matching: \.id, equalTo: id)
    let response = try await request.response()
    return response.items.first
  }

  func fetchPlaylist(id: MusicItemID) async throws -> Playlist? {
    let request = MusicCatalogResourceRequest<Playlist>(matching: \.id, equalTo: id)
    let response = try await request.response()
    return response.items.first
  }

  func fetchStation(id: MusicItemID) async throws -> Station? {
    let request = MusicCatalogResourceRequest<Station>(matching: \.id, equalTo: id)
    let response = try await request.response()
    return response.items.first
  }

  func fetchMusicVideo(id: MusicItemID) async throws -> MusicVideo? {
    let request = MusicCatalogResourceRequest<MusicVideo>(matching: \.id, equalTo: id)
    let response = try await request.response()
    return response.items.first
  }

  // MARK: - Batch catalog resources (REST)

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
