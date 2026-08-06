// RestJsonMapper.swift
// Maps Apple Music API JSON objects to bridge dictionaries (matches Android mapper).
// Golden REST cases: fixtures/*.json + fixtures/expected/*.json — see docs/BRIDGE_CONTRACT.md.

import Foundation

@available(iOS 16.0, macOS 13.0, *)
enum RestJsonMapper {

  static func mapAlbum(_ resource: [String: Any]) -> [String: Any] {
    let attributes = resource["attributes"] as? [String: Any] ?? [:]
    let trackCount: Int
    if let count = attributes["trackCount"] as? Int {
      trackCount = count
    } else if let count = attributes["trackCount"] as? Double {
      trackCount = Int(count)
    } else {
      trackCount = 0
    }
    return [
      "id": resource["id"] as? String ?? "",
      "title": attributes["name"] as? String ?? "",
      "artistName": attributes["artistName"] as? String ?? "",
      "artworkUrl": artworkUrl(attributes["artwork"] as? [String: Any]),
      "trackCount": trackCount,
    ]
  }

  static func mapSong(_ resource: [String: Any]) -> [String: Any] {
    let attributes = resource["attributes"] as? [String: Any] ?? [:]
    let id = catalogPlaybackId(resource) ?? (resource["id"] as? String ?? "")
    return [
      "id": id,
      "title": attributes["name"] as? String ?? "",
      "artistName": attributes["artistName"] as? String ?? "",
      "artworkUrl": artworkUrl(attributes["artwork"] as? [String: Any]),
      "duration": durationMillis(attributes),
    ]
  }

  static func mapArtist(_ resource: [String: Any]) -> [String: Any] {
    let attributes = resource["attributes"] as? [String: Any] ?? [:]
    return [
      "id": resource["id"] as? String ?? "",
      "name": attributes["name"] as? String ?? "",
      "artworkUrl": artworkUrl(attributes["artwork"] as? [String: Any]),
    ]
  }

  static func mapRecentResource(_ resource: [String: Any]) -> [String: Any] {
    let attributes = resource["attributes"] as? [String: Any] ?? [:]
    let apiType = resource["type"] as? String ?? ""
    let itemType: String
    if apiType.contains("album") {
      itemType = "album"
    } else if apiType.contains("playlist") {
      itemType = "playlist"
    } else if apiType.contains("station") {
      itemType = "station"
    } else {
      itemType = "unknown"
    }

    var subtitle = attributes["artistName"] as? String ?? ""
    if subtitle.isEmpty {
      subtitle = attributes["curatorName"] as? String ?? ""
    }
    if subtitle.isEmpty, let description = attributes["description"] as? [String: Any] {
      subtitle = description["standard"] as? String ?? ""
    }

    return [
      "id": resource["id"] as? String ?? "",
      "title": attributes["name"] as? String ?? "",
      "subtitle": subtitle,
      "type": itemType,
    ]
  }

  static func mapRecentlyPlayed(_ resource: [String: Any]) -> [String: Any] {
    mapRecentResource(resource)
  }

  static func mapPlaylist(_ resource: [String: Any]) -> [String: Any] {
    let attributes = resource["attributes"] as? [String: Any] ?? [:]
    var trackCount = 0
    if let count = attributes["trackCount"] as? Int {
      trackCount = count
    } else if let count = attributes["trackCount"] as? Double {
      trackCount = Int(count)
    }
    var description = attributes["description"] as? String ?? ""
    if description.isEmpty, let desc = attributes["description"] as? [String: Any] {
      description = desc["standard"] as? String ?? ""
    }
    return [
      "id": resource["id"] as? String ?? "",
      "name": attributes["name"] as? String ?? "",
      "description": description,
      "artworkUrl": artworkUrl(attributes["artwork"] as? [String: Any]),
      "trackCount": trackCount,
    ]
  }

  static func mapMusicVideo(_ resource: [String: Any]) -> [String: Any] {
    let attributes = resource["attributes"] as? [String: Any] ?? [:]
    let id = catalogPlaybackId(resource) ?? (resource["id"] as? String ?? "")
    return [
      "id": id,
      "title": attributes["name"] as? String ?? "",
      "artistName": attributes["artistName"] as? String ?? "",
      "artworkUrl": artworkUrl(attributes["artwork"] as? [String: Any]),
      "duration": durationMillis(attributes),
    ]
  }

  static func mapStation(_ resource: [String: Any]) -> [String: Any] {
    let attributes = resource["attributes"] as? [String: Any] ?? [:]
    return [
      "id": resource["id"] as? String ?? "",
      "name": attributes["name"] as? String ?? "",
      "artworkUrl": artworkUrl(attributes["artwork"] as? [String: Any]),
    ]
  }

  private static func catalogPlaybackId(_ resource: [String: Any]) -> String? {
    let attributes = resource["attributes"] as? [String: Any] ?? [:]
    guard let playParams = attributes["playParams"] as? [String: Any] else { return nil }
    if let id = playParams["id"] as? String, !id.isEmpty { return id }
    if let catalogId = playParams["catalogId"] as? String, !catalogId.isEmpty { return catalogId }
    return nil
  }

  /// Candidate catalog song ids for MusicKit lookup (playback id, resource id, playParams).
  static func catalogSongLookupIds(primaryId: String, resource: [String: Any]) -> [String] {
    var ids: [String] = []
    func append(_ value: String?) {
      guard let value, !value.isEmpty, !ids.contains(value) else { return }
      ids.append(value)
    }
    append(primaryId)
    append(resource["id"] as? String)
    append(catalogPlaybackId(resource))
    return ids
  }

  private static func durationMillis(_ attributes: [String: Any]) -> Int {
    if let millis = attributes["durationInMillis"] as? Int {
      return millis
    }
    if let millis = attributes["durationInMillis"] as? Double {
      return Int(millis)
    }
    if let duration = attributes["duration"] as? Double {
      return Int(duration * 1000)
    }
    return 0
  }

  private static func artworkUrl(_ artwork: [String: Any]?, width: Int = 200, height: Int = 200) -> String {
    guard let artwork, let template = artwork["url"] as? String, !template.isEmpty else {
      return ""
    }
    return template
      .replacingOccurrences(of: "{w}", with: "\(width)")
      .replacingOccurrences(of: "{h}", with: "\(height)")
  }

  static func mapRating(_ json: [String: Any]) -> [String: Any]? {
    guard let data = json["data"] as? [[String: Any]], let first = data.first else {
      return nil
    }
    let attributes = first["attributes"] as? [String: Any] ?? [:]
    let value = attributes["value"] as? Int ?? (attributes["value"] as? Double).map { Int($0) }
    guard let value else { return nil }
    return [
      "id": first["id"] as? String ?? "",
      "value": value,
    ]
  }

  static func mapRecommendation(_ resource: [String: Any]) -> [String: Any] {
    let attributes = resource["attributes"] as? [String: Any] ?? [:]
    let titleDict = attributes["title"] as? [String: Any]
    let title = titleDict?["stringForDisplay"] as? String ?? ""
    let resourceTypes = attributes["resourceTypes"] as? [String] ?? []
    let contents = mapRecommendationContents(resource)
    return [
      "id": resource["id"] as? String ?? "",
      "title": title,
      "resourceTypes": resourceTypes,
      "playlists": contents.playlists,
      "albums": contents.albums,
      "stations": contents.stations,
    ]
  }

  static func mapReplaySummary(_ resource: [String: Any]) -> [String: Any] {
    let attributes = resource["attributes"] as? [String: Any] ?? [:]
    let year = attributes["year"] as? Int ?? (attributes["year"] as? Double).map { Int($0) }
    var result: [String: Any] = [
      "id": resource["id"] as? String ?? "",
      "type": resource["type"] as? String ?? "",
      "name": attributes["name"] as? String ?? "",
      "topSongs": mapRelationshipResources(resource, key: "top-songs", mapper: mapSong),
      "topAlbums": mapRelationshipResources(resource, key: "top-albums", mapper: mapAlbum),
      "topArtists": mapRelationshipResources(resource, key: "top-artists", mapper: mapArtist),
    ]
    if let year {
      result["year"] = year
    }
    return result
  }

  private struct RecommendationContents {
    let playlists: [[String: Any]]
    let albums: [[String: Any]]
    let stations: [[String: Any]]
  }

  private static func mapRecommendationContents(_ resource: [String: Any]) -> RecommendationContents {
    var playlists: [[String: Any]] = []
    var albums: [[String: Any]] = []
    var stations: [[String: Any]] = []
    guard let relationships = resource["relationships"] as? [String: Any],
      let contents = relationships["contents"] as? [String: Any],
      let data = contents["data"] as? [[String: Any]]
    else {
      return RecommendationContents(playlists: playlists, albums: albums, stations: stations)
    }
    for item in data {
      let type = item["type"] as? String ?? ""
      if type.contains("playlist") {
        playlists.append(mapPlaylist(item))
      } else if type.contains("album") {
        albums.append(mapAlbum(item))
      } else if type.contains("station") {
        stations.append(mapStation(item))
      }
    }
    return RecommendationContents(playlists: playlists, albums: albums, stations: stations)
  }

  private static func mapRelationshipResources(
    _ resource: [String: Any],
    key: String,
    mapper: ([String: Any]) -> [String: Any]
  ) -> [[String: Any]] {
    guard let relationships = resource["relationships"] as? [String: Any],
      let relation = relationships[key] as? [String: Any],
      let data = relation["data"] as? [[String: Any]]
    else {
      return []
    }
    return data.map(mapper)
  }

  static func buildIdsQuery(_ resourceIds: [String: [String]]) -> [String: String] {
    var query: [String: String] = [:]
    for (type, ids) in resourceIds {
      let filtered = ids.filter { !$0.isEmpty }
      if !filtered.isEmpty {
        query["ids[\(type)]"] = filtered.joined(separator: ",")
      }
    }
    return query
  }
}
