// CatalogService+MusicKitFetch.swift
// Native MusicKit catalog get-by-id. Song fetch may consult REST only to resolve
// alternate catalog IDs when MusicKit misses (e.g. after REST search) — not a REST get path.

import Foundation
import MusicKit

@available(iOS 16.0, *)
extension CatalogService {

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
}
