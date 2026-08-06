// MusicItemMapper.swift
// Maps MusicKit types to bridge dictionaries (must match RestJsonMapper / AppleMusicJsonMapper).

import Foundation
import MusicKit

@available(iOS 16.0, *)
enum MusicItemMapper {

  // MARK: - Song

  static func map(_ song: Song) -> [String: Any] {
    [
      "id": catalogPlaybackId(from: song),
      "title": song.title,
      "artistName": song.artistName,
      "artworkUrl": extractArtworkURL(song.artwork),
      "duration": durationMillis(song.duration),
    ]
  }

  // MARK: - Album

  static func map(_ album: Album) -> [String: Any] {
    [
      "id": musicItemId(album.id),
      "title": album.title,
      "artistName": album.artistName,
      "artworkUrl": extractArtworkURL(album.artwork),
      "trackCount": album.trackCount,
    ]
  }

  // MARK: - Artist

  static func map(_ artist: Artist) -> [String: Any] {
    [
      "id": musicItemId(artist.id),
      "name": artist.name,
      "artworkUrl": extractArtworkURL(artist.artwork),
    ]
  }

  // MARK: - Playlist

  static func map(_ playlist: Playlist) -> [String: Any] {
    [
      "id": musicItemId(playlist.id),
      "name": playlist.name,
      "description": playlist.standardDescription ?? "",
      "artworkUrl": extractArtworkURL(playlist.artwork),
      "trackCount": playlistTrackCount(playlist),
    ]
  }

  // MARK: - Station

  static func map(_ station: Station) -> [String: Any] {
    [
      "id": musicItemId(station.id),
      "name": station.name,
      "artworkUrl": extractArtworkURL(station.artwork),
    ]
  }

  // MARK: - Personal recommendation

  /// Bridge shape matches `RestJsonMapper.mapRecommendation`.
  static func map(_ recommendation: MusicPersonalRecommendation) -> [String: Any] {
    [
      "id": musicItemId(recommendation.id),
      "title": recommendation.title ?? "",
      "resourceTypes": resourceTypes(from: recommendation),
      "playlists": recommendation.playlists.map { map($0) },
      "albums": recommendation.albums.map { map($0) },
      "stations": recommendation.stations.map { map($0) },
    ]
  }

  private static func resourceTypes(from recommendation: MusicPersonalRecommendation) -> [String] {
    var types: [String] = []
    for itemType in recommendation.types {
      if itemType == Playlist.self {
        types.append("playlists")
      } else if itemType == Album.self {
        types.append("albums")
      } else if itemType == Station.self {
        types.append("stations")
      }
    }
    if !types.isEmpty {
      return types
    }
    // Fallback when MusicKit omits `types` but collections are populated.
    if !recommendation.playlists.isEmpty { types.append("playlists") }
    if !recommendation.albums.isEmpty { types.append("albums") }
    if !recommendation.stations.isEmpty { types.append("stations") }
    return types
  }

  // MARK: - Music Video

  @available(iOS 16.0, *)
  static func map(_ musicVideo: MusicVideo) -> [String: Any] {
    [
      "id": catalogPlaybackId(from: musicVideo),
      "title": musicVideo.title,
      "artistName": musicVideo.artistName,
      "artworkUrl": extractArtworkURL(musicVideo.artwork),
      "duration": durationMillis(musicVideo.duration),
    ]
  }

  // MARK: - Recently Played Items

  @available(iOS 16.0, *)
  static func map(_ item: RecentlyPlayedMusicItem) -> [String: Any] {
    var result: [String: Any] = [
      "id": musicItemId(item.id),
      "title": item.title,
      "subtitle": String(describing: item.subtitle ?? ""),
    ]

    switch item {
    case .album:
      result["type"] = "album"
    case .playlist:
      result["type"] = "playlist"
    case .station:
      result["type"] = "station"
    default:
      result["type"] = "unknown"
    }

    return result
  }

  // MARK: - Playback Status

  static func describePlaybackStatus(_ status: MusicPlayer.PlaybackStatus) -> String {
    switch status {
    case .playing: return "playing"
    case .paused: return "paused"
    case .stopped: return "stopped"
    case .interrupted: return "interrupted"
    case .seekingForward: return "seekingForward"
    case .seekingBackward: return "seekingBackward"
    @unknown default: return "unknown"
    }
  }

  // MARK: - ID & duration helpers (parity with RestJsonMapper / Android)

  static func musicItemId(_ id: MusicItemID) -> String {
    id.rawValue
  }

  static func catalogPlaybackId(from song: Song) -> String {
    if let playId = catalogPlaybackId(from: song.playParameters) {
      return playId
    }
    return musicItemId(song.id)
  }

  static func catalogPlaybackId(from musicVideo: MusicVideo) -> String {
    if let playId = catalogPlaybackId(from: musicVideo.playParameters) {
      return playId
    }
    return musicItemId(musicVideo.id)
  }

  /// MusicKit no longer exposes `PlayParameters.id`; decode Codable payload (parity with RestJsonMapper).
  private static func catalogPlaybackId(from playParameters: PlayParameters?) -> String? {
    guard let playParameters,
          let data = try? JSONEncoder().encode(playParameters),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else { return nil }
    return BridgeMapperHelpers.catalogPlaybackId(fromPlayParams: json)
  }

  /// MusicKit `duration` is seconds; bridge uses milliseconds (matches `durationInMillis` from REST).
  static func durationMillis(_ seconds: TimeInterval?) -> Int {
    BridgeMapperHelpers.durationMillis(fromSeconds: seconds)
  }

  private static func playlistTrackCount(_ playlist: Playlist) -> Int {
    if let count = playlist.tracks?.count, count > 0 {
      return count
    }
    return playlist.entries?.count ?? 0
  }

  // MARK: - Private Helpers

  private static func extractArtworkURL(_ artwork: Artwork?, width: Int = 200, height: Int = 200) -> String {
    guard let artwork = artwork,
          let url = artwork.url(width: width, height: height),
          url.scheme == "https" || url.scheme == "http"
    else {
      return ""
    }
    return url.absoluteString
  }
}
