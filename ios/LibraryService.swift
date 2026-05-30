// LibraryService.swift
// Handles user's Apple Music library operations via REST (parity with Android/web).

import Foundation
import MusicKit

@available(iOS 16.0, *)
final class LibraryService {

  func getArtists(musicUserToken: String, options: BridgePagination) async throws -> [[String: Any]] {
    let data = try await AppleMusicRestClient.getDataArray(
      path: "/v1/me/library/artists",
      musicUserToken: musicUserToken,
      query: ["limit": "\(options.limit)", "offset": "\(options.offset)"]
    )
    return data.map(RestJsonMapper.mapArtist)
  }

  func getAlbums(musicUserToken: String, options: BridgePagination) async throws -> [[String: Any]] {
    let data = try await AppleMusicRestClient.getDataArray(
      path: "/v1/me/library/albums",
      musicUserToken: musicUserToken,
      query: ["limit": "\(options.limit)", "offset": "\(options.offset)"]
    )
    return data.map(RestJsonMapper.mapAlbum)
  }

  func getPlaylists(musicUserToken: String, options: BridgePagination) async throws -> [[String: Any]] {
    let data = try await AppleMusicRestClient.getDataArray(
      path: "/v1/me/library/playlists",
      musicUserToken: musicUserToken,
      query: ["limit": "\(options.limit)", "offset": "\(options.offset)"]
    )
    return data.map(RestJsonMapper.mapPlaylist)
  }

  func getPlaylistSongs(musicUserToken: String, playlistId: String) async throws -> [[String: Any]] {
    let json = try await AppleMusicRestClient.get(
      path: "/v1/me/library/playlists/\(playlistId)/tracks",
      musicUserToken: musicUserToken
    )
    guard let data = json["data"] as? [[String: Any]] else {
      throw LibraryServiceError.playlistNotFound
    }
    return data.compactMap { row -> [String: Any]? in
      guard let type = row["type"] as? String, type.contains("song") else { return nil }
      return RestJsonMapper.mapSong(row)
    }
  }

  func getSongs(musicUserToken: String, options: BridgePagination) async throws -> [[String: Any]] {
    let data = try await AppleMusicRestClient.getDataArray(
      path: "/v1/me/library/songs",
      musicUserToken: musicUserToken,
      query: ["limit": "\(options.limit)", "offset": "\(options.offset)"]
    )
    return data.map(RestJsonMapper.mapSong)
  }

  func getMusicVideos(musicUserToken: String, options: BridgePagination) async throws -> [[String: Any]] {
    let data = try await AppleMusicRestClient.getDataArray(
      path: "/v1/me/library/music-videos",
      musicUserToken: musicUserToken,
      query: ["limit": "\(options.limit)", "offset": "\(options.offset)"]
    )
    return data.map(RestJsonMapper.mapMusicVideo)
  }

  struct LibrarySearchResult {
    let songs: [[String: Any]]
    let albums: [[String: Any]]
    let artists: [[String: Any]]
    let playlists: [[String: Any]]
    let musicVideos: [[String: Any]]
  }

  func search(
    musicUserToken: String,
    term: String,
    types: [String],
    options: BridgePagination
  ) async throws -> LibrarySearchResult {
    let typeParam = Array(Set(types.compactMap { Self.librarySearchRestTypeParam($0) })).sorted().joined(
      separator: ",")
    let typesQuery = typeParam.isEmpty ? "library-songs,library-albums" : typeParam

    let json = try await AppleMusicRestClient.get(
      path: "/v1/me/library/search",
      musicUserToken: musicUserToken,
      query: [
        "term": term,
        "types": typesQuery,
        "limit": "\(options.limit)",
        "offset": "\(options.offset)",
      ]
    )

    let results = json["results"] as? [String: Any] ?? [:]
    return LibrarySearchResult(
      songs: parseLibrarySearchBucket(results: results, key: "library-songs", mapper: RestJsonMapper.mapSong),
      albums: parseLibrarySearchBucket(results: results, key: "library-albums", mapper: RestJsonMapper.mapAlbum),
      artists: parseLibrarySearchBucket(results: results, key: "library-artists", mapper: RestJsonMapper.mapArtist),
      playlists: parseLibrarySearchBucket(
        results: results, key: "library-playlists", mapper: RestJsonMapper.mapPlaylist),
      musicVideos: parseLibrarySearchBucket(
        results: results, key: "library-music-videos", mapper: RestJsonMapper.mapMusicVideo)
    )
  }

  private func parseLibrarySearchBucket(
    results: [String: Any],
    key: String,
    mapper: ([String: Any]) -> [String: Any]
  ) -> [[String: Any]] {
    guard let bucket = results[key] as? [String: Any],
      let data = bucket["data"] as? [[String: Any]]
    else {
      return []
    }
    return data.map(mapper)
  }

  private static func librarySearchRestTypeParam(_ type: String) -> String? {
    switch type {
    case "library-songs", "songs": return "library-songs"
    case "library-albums", "albums": return "library-albums"
    case "library-artists", "artists": return "library-artists"
    case "library-playlists", "playlists": return "library-playlists"
    case "library-music-videos", "music-videos", "musicVideos": return "library-music-videos"
    default: return nil
    }
  }

  // MARK: - Native MusicKit (library playback queue only)

  func fetchSong(id: MusicItemID) async throws -> Song? {
    var request = MusicLibraryRequest<Song>()
    request.filter(matching: \.id, equalTo: id)
    let response = try await request.response()
    return response.items.first
  }

  func fetchAlbum(id: MusicItemID) async throws -> Album? {
    var request = MusicLibraryRequest<Album>()
    request.filter(matching: \.id, equalTo: id)
    let response = try await request.response()
    return response.items.first
  }

  func fetchPlaylist(id: MusicItemID) async throws -> Playlist? {
    var request = MusicLibraryRequest<Playlist>()
    request.filter(matching: \.id, equalTo: id)
    let response = try await request.response()
    guard let playlist = response.items.first else { return nil }
    return try await playlist.with([.tracks])
  }

  func extractSongs(from playlist: Playlist) async throws -> [Song] {
    let detailed = try await playlist.with([.tracks])
    guard let tracks = detailed.tracks else { return [] }

    var songs: [Song] = []
    for track in tracks {
      if case .song(let song) = track {
        songs.append(song)
      }
    }
    return songs
  }
}

// MARK: - Errors

enum LibraryServiceError: LocalizedError {
  case playlistNotFound
  case songNotFound
  case albumNotFound
  case noTracksInPlaylist
  case noSongsInPlaylist

  var errorDescription: String? {
    switch self {
    case .playlistNotFound: return "Playlist not found in library"
    case .songNotFound: return "Song not found in library"
    case .albumNotFound: return "Album not found in library"
    case .noTracksInPlaylist: return "No tracks in playlist"
    case .noSongsInPlaylist: return "No songs in playlist"
    }
  }
}
