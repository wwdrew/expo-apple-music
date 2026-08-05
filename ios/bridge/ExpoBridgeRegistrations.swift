import ExpoModulesCore
import Foundation

/// Registers domain bridge `AsyncFunction` / `Function` definitions.
///
/// Swift’s `ModuleDefinitionBuilder` cannot call Android-style `register*Bridge`
/// helpers inside the result builder. Instead each domain returns `[AnyDefinition]`
/// and `ExpoAppleMusicModule._exposedDefinition()` merges them (same hook the
/// `@ExpoModule` macro uses).
@available(iOS 16.0, *)
enum ExpoBridgeRegistrations {
  static func all(module: ExpoAppleMusicModule) -> [AnyDefinition] {
    auth(module: module)
      + catalog(module: module)
      + library(module: module)
      + history(module: module)
      + player(module: module)
      + ratings(module: module)
      + libraryMutations(module: module)
      + recommendations(module: module)
  }

  // MARK: - Auth

  static func auth(module: ExpoAppleMusicModule) -> [AnyDefinition] {
    [
      AsyncFunction("setDeveloperToken") { (token: String) in
        MusicKitAuthStorage.saveDeveloperToken(token)
      },
      AsyncFunction("authorization") {
        (developerToken: String?, _ startScreenMessage: String?, _ hideStartScreen: Bool?) -> [String: Any?] in
        await ExpoBridgeAuth.authorization(
          subscriptionService: module.subscriptionService,
          developerToken: developerToken,
          startScreenMessage: startScreenMessage,
          hideStartScreen: hideStartScreen
        )
      },
      AsyncFunction("checkSubscription") { (_ musicUserToken: String) -> [String: Any] in
        try await ExpoBridgeAuth.checkSubscription(subscriptionService: module.subscriptionService)
      },
      AsyncFunction("getStorefront") { (musicUserToken: String) -> [String: Any] in
        try await ExpoBridgeAuth.getStorefront(musicUserToken: musicUserToken)
      },
    ]
  }

  // MARK: - Catalog

  static func catalog(module: ExpoAppleMusicModule) -> [AnyDefinition] {
    [
      AsyncFunction("catalogSearch") { (term: String, types: [String], options: [String: Any]) -> [String: Any] in
        try await ExpoBridgeCatalog.catalogSearch(
          service: module.catalogService,
          term: term,
          types: types,
          options: options as NSDictionary
        )
      },
      AsyncFunction("getCatalogSong") { (id: String) -> [String: Any] in
        try await ExpoBridgeCatalog.getCatalogSong(service: module.catalogService, id: id)
      },
      AsyncFunction("getCatalogAlbum") { (id: String) -> [String: Any] in
        try await ExpoBridgeCatalog.getCatalogAlbum(service: module.catalogService, id: id)
      },
      AsyncFunction("getCatalogArtist") { (id: String) -> [String: Any] in
        try await ExpoBridgeCatalog.getCatalogArtist(service: module.catalogService, id: id)
      },
      AsyncFunction("getCatalogPlaylist") { (id: String) -> [String: Any] in
        try await ExpoBridgeCatalog.getCatalogPlaylist(service: module.catalogService, id: id)
      },
      AsyncFunction("getCatalogStation") { (id: String) -> [String: Any] in
        try await ExpoBridgeCatalog.getCatalogStation(service: module.catalogService, id: id)
      },
      AsyncFunction("getCatalogMusicVideo") { (id: String) -> [String: Any] in
        try await ExpoBridgeCatalog.getCatalogMusicVideo(service: module.catalogService, id: id)
      },
      AsyncFunction("getCatalogAlbumTracks") { (albumId: String, options: [String: Any]) -> [String: Any] in
        try await ExpoBridgeCatalog.getCatalogAlbumTracks(
          service: module.catalogService,
          albumId: albumId,
          options: options as NSDictionary
        )
      },
      AsyncFunction("getCatalogArtistAlbums") { (artistId: String, options: [String: Any]) -> [String: Any] in
        try await ExpoBridgeCatalog.getCatalogArtistAlbums(
          service: module.catalogService,
          artistId: artistId,
          options: options as NSDictionary
        )
      },
      AsyncFunction("getCatalogPlaylistTracks") { (playlistId: String, options: [String: Any]) -> [String: Any] in
        try await ExpoBridgeCatalog.getCatalogPlaylistTracks(
          service: module.catalogService,
          playlistId: playlistId,
          options: options as NSDictionary
        )
      },
      AsyncFunction("getCatalogCharts") { (types: [String], options: [String: Any]) -> [String: Any] in
        try await ExpoBridgeCatalog.getCatalogCharts(
          service: module.catalogService,
          types: types,
          options: options
        )
      },
      AsyncFunction("getCatalogResources") { (type: String, ids: [String]) -> [String: Any] in
        try await ExpoBridgeCatalog.getCatalogResources(
          service: module.catalogService,
          type: type,
          ids: ids
        )
      },
    ]
  }

  // MARK: - Library

  static func library(module: ExpoAppleMusicModule) -> [AnyDefinition] {
    [
      AsyncFunction("getUserPlaylists") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
        try await ExpoBridgeLibrary.getUserPlaylists(
          service: module.libraryService,
          musicUserToken: musicUserToken,
          options: options as NSDictionary
        )
      },
      AsyncFunction("getLibrarySongs") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
        try await ExpoBridgeLibrary.getLibrarySongs(
          service: module.libraryService,
          musicUserToken: musicUserToken,
          options: options as NSDictionary
        )
      },
      AsyncFunction("getPlaylistSongs") {
        (musicUserToken: String, playlistId: String, _ options: [String: Any]) -> [String: Any] in
        try await ExpoBridgeLibrary.getPlaylistSongs(
          service: module.libraryService,
          musicUserToken: musicUserToken,
          playlistId: playlistId
        )
      },
      AsyncFunction("getLibraryArtists") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
        try await ExpoBridgeLibrary.getLibraryArtists(
          service: module.libraryService,
          musicUserToken: musicUserToken,
          options: options as NSDictionary
        )
      },
      AsyncFunction("getLibraryAlbums") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
        try await ExpoBridgeLibrary.getLibraryAlbums(
          service: module.libraryService,
          musicUserToken: musicUserToken,
          options: options as NSDictionary
        )
      },
      AsyncFunction("getLibraryMusicVideos") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
        try await ExpoBridgeLibrary.getLibraryMusicVideos(
          service: module.libraryService,
          musicUserToken: musicUserToken,
          options: options as NSDictionary
        )
      },
      AsyncFunction("librarySearch") {
        (musicUserToken: String, term: String, types: [String], options: [String: Any]) -> [String: Any] in
        try await ExpoBridgeLibrary.librarySearch(
          service: module.libraryService,
          musicUserToken: musicUserToken,
          term: term,
          types: types,
          options: options as NSDictionary
        )
      },
    ]
  }

  // MARK: - History

  static func history(module: ExpoAppleMusicModule) -> [AnyDefinition] {
    [
      AsyncFunction("getRecentlyPlayedResources") { (musicUserToken: String) -> [String: Any] in
        try await ExpoBridgeHistory.getRecentlyPlayedResources(
          service: module.historyService,
          musicUserToken: musicUserToken
        )
      },
      AsyncFunction("getRecentlyPlayedTracks") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
        try await ExpoBridgeHistory.getRecentlyPlayedTracks(
          service: module.historyService,
          musicUserToken: musicUserToken,
          options: options as NSDictionary
        )
      },
      AsyncFunction("getHeavyRotation") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
        try await ExpoBridgeHistory.getHeavyRotation(
          service: module.historyService,
          musicUserToken: musicUserToken,
          options: options as NSDictionary
        )
      },
      AsyncFunction("getRecentlyPlayedStations") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
        try await ExpoBridgeHistory.getRecentlyPlayedStations(
          service: module.historyService,
          musicUserToken: musicUserToken,
          options: options as NSDictionary
        )
      },
      AsyncFunction("getRecentlyAdded") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
        try await ExpoBridgeHistory.getRecentlyAdded(
          service: module.historyService,
          musicUserToken: musicUserToken,
          options: options as NSDictionary
        )
      },
    ]
  }

  // MARK: - Player

  static func player(module: ExpoAppleMusicModule) -> [AnyDefinition] {
    [
      AsyncFunction("setPlaybackQueue") { (itemId: String, type: String) -> String in
        try await ExpoBridgePlayer.setPlaybackQueue(
          queueService: module.queueService,
          itemId: itemId,
          type: type
        )
      },
      AsyncFunction("configurePlayer") { (options: [String: Any]) -> [String: Any] in
        try module.playbackController.configurePlayer(options: options)
      },
      Function("play") {
        Task {
          do {
            try await module.playbackController.play()
          } catch {
            module.emitPlaybackError(error, operation: "play")
          }
        }
      },
      Function("pause") {
        module.playbackController.pause()
      },
      Function("skipToNextEntry") {
        Task {
          do {
            try await module.playbackController.skipToNext()
          } catch {
            module.emitPlaybackError(error, operation: "skipToNext")
          }
        }
      },
      Function("skipToPreviousEntry") {
        Task {
          do {
            try await module.playbackController.skipToPrevious()
          } catch {
            module.emitPlaybackError(error, operation: "skipToPrevious")
          }
        }
      },
      Function("restartCurrentEntry") {
        Task { @MainActor in
          module.playbackController.restartCurrentEntry()
          module.playbackTimeDidUpdate(0)
        }
      },
      Function("seekToTime") { (time: Double) in
        Task { @MainActor in
          module.playbackController.seek(to: time)
          module.playbackTimeDidUpdate(time)
        }
      },
      Function("togglePlayerState") {
        Task {
          do {
            try await module.playbackController.togglePlayback()
          } catch {
            module.emitPlaybackError(error, operation: "togglePlayback")
          }
        }
      },
      AsyncFunction("getCurrentState") { () -> [String: Any] in
        await ExpoBridgePlayer.getCurrentState(playbackController: module.playbackController)
      },
      AsyncFunction("playLibrarySong") { (musicUserToken: String, songId: String) -> String in
        try await ExpoBridgePlayer.playLibrarySong(
          queueService: module.queueService,
          musicUserToken: musicUserToken,
          songId: songId
        )
      },
      AsyncFunction("playLibraryPlaylist") {
        (musicUserToken: String, playlistId: String, startingAt: Int) -> String in
        try await ExpoBridgePlayer.playLibraryPlaylist(
          queueService: module.queueService,
          musicUserToken: musicUserToken,
          playlistId: playlistId,
          startingAt: startingAt
        )
      },
    ]
  }

  // MARK: - Ratings

  static func ratings(module: ExpoAppleMusicModule) -> [AnyDefinition] {
    [
      AsyncFunction("getRating") {
        (musicUserToken: String, resourceType: String, id: String) -> [String: Any]? in
        try await ExpoBridgeRatings.getRating(
          service: module.ratingsService,
          musicUserToken: musicUserToken,
          resourceType: resourceType,
          id: id
        )
      },
      AsyncFunction("setRating") {
        (musicUserToken: String, resourceType: String, id: String, value: Int) -> [String: Any] in
        try await ExpoBridgeRatings.setRating(
          service: module.ratingsService,
          musicUserToken: musicUserToken,
          resourceType: resourceType,
          id: id,
          value: value
        )
      },
      AsyncFunction("clearRating") { (musicUserToken: String, resourceType: String, id: String) in
        try await ExpoBridgeRatings.clearRating(
          service: module.ratingsService,
          musicUserToken: musicUserToken,
          resourceType: resourceType,
          id: id
        )
      },
      AsyncFunction("addToFavorites") { (musicUserToken: String, resourceIds: [String: [String]]) in
        try await ExpoBridgeRatings.addToFavorites(
          service: module.ratingsService,
          musicUserToken: musicUserToken,
          resourceIds: resourceIds
        )
      },
      AsyncFunction("removeFromFavorites") { (musicUserToken: String, resourceIds: [String: [String]]) in
        try await ExpoBridgeRatings.removeFromFavorites(
          service: module.ratingsService,
          musicUserToken: musicUserToken,
          resourceIds: resourceIds
        )
      },
    ]
  }

  // MARK: - Library mutations

  static func libraryMutations(module: ExpoAppleMusicModule) -> [AnyDefinition] {
    [
      AsyncFunction("addToLibrary") { (musicUserToken: String, resourceIds: [String: [String]]) in
        try await ExpoBridgeLibraryMutations.addToLibrary(
          service: module.libraryMutationsService,
          musicUserToken: musicUserToken,
          resourceIds: resourceIds
        )
      },
      AsyncFunction("createLibraryPlaylist") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
        try await ExpoBridgeLibraryMutations.createLibraryPlaylist(
          service: module.libraryMutationsService,
          musicUserToken: musicUserToken,
          options: options
        )
      },
      AsyncFunction("addTracksToLibraryPlaylist") {
        (musicUserToken: String, playlistId: String, tracks: [[String: String]]) in
        try await ExpoBridgeLibraryMutations.addTracksToLibraryPlaylist(
          service: module.libraryMutationsService,
          musicUserToken: musicUserToken,
          playlistId: playlistId,
          tracks: tracks
        )
      },
    ]
  }

  // MARK: - Recommendations

  static func recommendations(module: ExpoAppleMusicModule) -> [AnyDefinition] {
    [
      AsyncFunction("getRecommendations") { (musicUserToken: String, ids: [String]?) -> [String: Any] in
        try await ExpoBridgeRecommendations.getRecommendations(
          service: module.recommendationsService,
          musicUserToken: musicUserToken,
          ids: ids
        )
      },
      AsyncFunction("getReplay") { (musicUserToken: String, year: Int?) -> [String: Any] in
        try await ExpoBridgeRecommendations.getReplay(
          service: module.recommendationsService,
          musicUserToken: musicUserToken,
          year: year
        )
      },
    ]
  }
}
