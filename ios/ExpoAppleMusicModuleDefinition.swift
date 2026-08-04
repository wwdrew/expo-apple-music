import ExpoModulesCore

@available(iOS 16.0, *)
extension ExpoAppleMusicModule {
  @ModuleDefinitionBuilder
  public func definition() -> ModuleDefinition {
    Name("ExpoAppleMusic")

    Events(
      "onPlaybackStateChange",
      "onCurrentSongChange",
      "onPlaybackTimeUpdate",
      "onPlaybackError"
    )

    OnStartObserving {
      let observer = PlaybackObserver(playbackController: self.playbackController)
      observer.delegate = self
      observer.startObserving()
      self.playbackObserver = observer
    }

    OnStopObserving {
      self.playbackObserver?.stopObserving()
      self.playbackObserver = nil
    }

    // MARK: - Auth (ExpoBridgeAuth)

    AsyncFunction("setDeveloperToken") { (token: String) in
      MusicKitAuthStorage.saveDeveloperToken(token)
    }

    AsyncFunction("authorization") { (developerToken: String?, _ startScreenMessage: String?, _ hideStartScreen: Bool?) -> [String: Any?] in
      await ExpoBridgeAuth.authorization(
        subscriptionService: self.subscriptionService,
        developerToken: developerToken,
        startScreenMessage: startScreenMessage,
        hideStartScreen: hideStartScreen
      )
    }

    AsyncFunction("checkSubscription") { (musicUserToken: String) -> [String: Any] in
      try await ExpoBridgeAuth.checkSubscription(subscriptionService: self.subscriptionService)
    }

    AsyncFunction("getStorefront") { (musicUserToken: String) -> [String: Any] in
      try await ExpoBridgeAuth.getStorefront(musicUserToken: musicUserToken)
    }

    // MARK: - Catalog (ExpoBridgeCatalog)

    AsyncFunction("catalogSearch") { (term: String, types: [String], options: [String: Any]) -> [String: Any] in
      try await ExpoBridgeCatalog.catalogSearch(
        service: self.catalogService,
        term: term,
        types: types,
        options: options as NSDictionary
      )
    }

    AsyncFunction("getCatalogSong") { (id: String) -> [String: Any] in
      try await ExpoBridgeCatalog.getCatalogSong(service: self.catalogService, id: id)
    }

    AsyncFunction("getCatalogAlbum") { (id: String) -> [String: Any] in
      try await ExpoBridgeCatalog.getCatalogAlbum(service: self.catalogService, id: id)
    }

    AsyncFunction("getCatalogArtist") { (id: String) -> [String: Any] in
      try await ExpoBridgeCatalog.getCatalogArtist(service: self.catalogService, id: id)
    }

    AsyncFunction("getCatalogPlaylist") { (id: String) -> [String: Any] in
      try await ExpoBridgeCatalog.getCatalogPlaylist(service: self.catalogService, id: id)
    }

    AsyncFunction("getCatalogStation") { (id: String) -> [String: Any] in
      try await ExpoBridgeCatalog.getCatalogStation(service: self.catalogService, id: id)
    }

    AsyncFunction("getCatalogMusicVideo") { (id: String) -> [String: Any] in
      try await ExpoBridgeCatalog.getCatalogMusicVideo(service: self.catalogService, id: id)
    }

    AsyncFunction("getCatalogAlbumTracks") { (albumId: String, options: [String: Any]) -> [String: Any] in
      try await ExpoBridgeCatalog.getCatalogAlbumTracks(
        service: self.catalogService,
        albumId: albumId,
        options: options as NSDictionary
      )
    }

    AsyncFunction("getCatalogArtistAlbums") { (artistId: String, options: [String: Any]) -> [String: Any] in
      try await ExpoBridgeCatalog.getCatalogArtistAlbums(
        service: self.catalogService,
        artistId: artistId,
        options: options as NSDictionary
      )
    }

    AsyncFunction("getCatalogPlaylistTracks") { (playlistId: String, options: [String: Any]) -> [String: Any] in
      try await ExpoBridgeCatalog.getCatalogPlaylistTracks(
        service: self.catalogService,
        playlistId: playlistId,
        options: options as NSDictionary
      )
    }

    AsyncFunction("getCatalogCharts") { (types: [String], options: [String: Any]) -> [String: Any] in
      try await ExpoBridgeCatalog.getCatalogCharts(
        service: self.catalogService,
        types: types,
        options: options
      )
    }

    AsyncFunction("getCatalogResources") { (type: String, ids: [String]) -> [String: Any] in
      try await ExpoBridgeCatalog.getCatalogResources(
        service: self.catalogService,
        type: type,
        ids: ids
      )
    }

    // MARK: - Library (ExpoBridgeLibrary)

    AsyncFunction("getUserPlaylists") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
      try await ExpoBridgeLibrary.getUserPlaylists(
        service: self.libraryService,
        musicUserToken: musicUserToken,
        options: options as NSDictionary
      )
    }

    AsyncFunction("getLibrarySongs") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
      try await ExpoBridgeLibrary.getLibrarySongs(
        service: self.libraryService,
        musicUserToken: musicUserToken,
        options: options as NSDictionary
      )
    }

    AsyncFunction("getPlaylistSongs") { (musicUserToken: String, playlistId: String, options: [String: Any]) -> [String: Any] in
      try await ExpoBridgeLibrary.getPlaylistSongs(
        service: self.libraryService,
        musicUserToken: musicUserToken,
        playlistId: playlistId
      )
    }

    AsyncFunction("getLibraryArtists") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
      try await ExpoBridgeLibrary.getLibraryArtists(
        service: self.libraryService,
        musicUserToken: musicUserToken,
        options: options as NSDictionary
      )
    }

    AsyncFunction("getLibraryAlbums") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
      try await ExpoBridgeLibrary.getLibraryAlbums(
        service: self.libraryService,
        musicUserToken: musicUserToken,
        options: options as NSDictionary
      )
    }

    AsyncFunction("getLibraryMusicVideos") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
      try await ExpoBridgeLibrary.getLibraryMusicVideos(
        service: self.libraryService,
        musicUserToken: musicUserToken,
        options: options as NSDictionary
      )
    }

    AsyncFunction("librarySearch") { (musicUserToken: String, term: String, types: [String], options: [String: Any]) -> [String: Any] in
      try await ExpoBridgeLibrary.librarySearch(
        service: self.libraryService,
        musicUserToken: musicUserToken,
        term: term,
        types: types,
        options: options as NSDictionary
      )
    }

    // MARK: - History (ExpoBridgeHistory)

    AsyncFunction("getRecentlyPlayedResources") { (musicUserToken: String) -> [String: Any] in
      try await ExpoBridgeHistory.getRecentlyPlayedResources(
        service: self.historyService,
        musicUserToken: musicUserToken)
    }

    AsyncFunction("getRecentlyPlayedTracks") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
      try await ExpoBridgeHistory.getRecentlyPlayedTracks(
        service: self.historyService,
        musicUserToken: musicUserToken,
        options: options as NSDictionary
      )
    }

    AsyncFunction("getHeavyRotation") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
      try await ExpoBridgeHistory.getHeavyRotation(
        service: self.historyService,
        musicUserToken: musicUserToken,
        options: options as NSDictionary
      )
    }

    AsyncFunction("getRecentlyPlayedStations") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
      try await ExpoBridgeHistory.getRecentlyPlayedStations(
        service: self.historyService,
        musicUserToken: musicUserToken,
        options: options as NSDictionary
      )
    }

    AsyncFunction("getRecentlyAdded") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
      try await ExpoBridgeHistory.getRecentlyAdded(
        service: self.historyService,
        musicUserToken: musicUserToken,
        options: options as NSDictionary
      )
    }

    // MARK: - Player (ExpoBridgePlayer)

    AsyncFunction("setPlaybackQueue") { (itemId: String, type: String) -> String in
      try await ExpoBridgePlayer.setPlaybackQueue(
        queueService: self.queueService,
        itemId: itemId,
        type: type
      )
    }

    AsyncFunction("configurePlayer") { (options: [String: Any]) -> [String: Any] in
      let configured = try self.playbackController.configurePlayer(options: options)
      return BridgeResponses.configurePlayer(options: configured)
    }

    Function("play") {
      Task {
        do {
          try await self.playbackController.play()
        } catch {
          self.emitPlaybackError(error, operation: "play")
        }
      }
    }

    Function("pause") {
      self.playbackController.pause()
    }

    Function("skipToNextEntry") {
      Task {
        do {
          try await self.playbackController.skipToNext()
        } catch {
          self.emitPlaybackError(error, operation: "skipToNext")
        }
      }
    }

    Function("skipToPreviousEntry") {
      Task {
        do {
          try await self.playbackController.skipToPrevious()
        } catch {
          self.emitPlaybackError(error, operation: "skipToPrevious")
        }
      }
    }

    Function("restartCurrentEntry") {
      Task { @MainActor in
        self.playbackController.restartCurrentEntry()
        self.playbackTimeDidUpdate(0)
      }
    }

    Function("seekToTime") { (time: Double) in
      Task { @MainActor in
        self.playbackController.seek(to: time)
        self.playbackTimeDidUpdate(time)
      }
    }

    Function("togglePlayerState") {
      Task {
        do {
          try await self.playbackController.togglePlayback()
        } catch {
          self.emitPlaybackError(error, operation: "togglePlayback")
        }
      }
    }

    AsyncFunction("getCurrentState") { () -> [String: Any] in
      await ExpoBridgePlayer.getCurrentState(playbackController: self.playbackController)
    }

    AsyncFunction("playLibrarySong") { (musicUserToken: String, songId: String) -> String in
      try await ExpoBridgePlayer.playLibrarySong(
        queueService: self.queueService,
        musicUserToken: musicUserToken,
        songId: songId
      )
    }

    AsyncFunction("playLibraryPlaylist") { (musicUserToken: String, playlistId: String, startingAt: Int) -> String in
      try await ExpoBridgePlayer.playLibraryPlaylist(
        queueService: self.queueService,
        musicUserToken: musicUserToken,
        playlistId: playlistId,
        startingAt: startingAt
      )
    }

    // MARK: - Ratings (ExpoBridgeRatings)

    AsyncFunction("getRating") { (musicUserToken: String, resourceType: String, id: String) -> [String: Any]? in
      try await ExpoBridgeRatings.getRating(
        service: self.ratingsService,
        musicUserToken: musicUserToken,
        resourceType: resourceType,
        id: id
      )
    }

    AsyncFunction("setRating") { (musicUserToken: String, resourceType: String, id: String, value: Int) -> [String: Any] in
      try await ExpoBridgeRatings.setRating(
        service: self.ratingsService,
        musicUserToken: musicUserToken,
        resourceType: resourceType,
        id: id,
        value: value
      )
    }

    AsyncFunction("clearRating") { (musicUserToken: String, resourceType: String, id: String) -> Void in
      try await ExpoBridgeRatings.clearRating(
        service: self.ratingsService,
        musicUserToken: musicUserToken,
        resourceType: resourceType,
        id: id
      )
    }

    AsyncFunction("addToFavorites") { (musicUserToken: String, resourceIds: [String: [String]]) -> Void in
      try await ExpoBridgeRatings.addToFavorites(
        service: self.ratingsService,
        musicUserToken: musicUserToken,
        resourceIds: resourceIds
      )
    }

    AsyncFunction("removeFromFavorites") { (musicUserToken: String, resourceIds: [String: [String]]) -> Void in
      try await ExpoBridgeRatings.removeFromFavorites(
        service: self.ratingsService,
        musicUserToken: musicUserToken,
        resourceIds: resourceIds
      )
    }

    // MARK: - Library mutations (ExpoBridgeLibraryMutations)

    AsyncFunction("addToLibrary") { (musicUserToken: String, resourceIds: [String: [String]]) -> Void in
      try await ExpoBridgeLibraryMutations.addToLibrary(
        service: self.libraryMutationsService,
        musicUserToken: musicUserToken,
        resourceIds: resourceIds
      )
    }

    AsyncFunction("createLibraryPlaylist") { (musicUserToken: String, options: [String: Any]) -> [String: Any] in
      try await ExpoBridgeLibraryMutations.createLibraryPlaylist(
        service: self.libraryMutationsService,
        musicUserToken: musicUserToken,
        options: options
      )
    }

    AsyncFunction("addTracksToLibraryPlaylist") { (musicUserToken: String, playlistId: String, tracks: [[String: String]]) -> Void in
      try await ExpoBridgeLibraryMutations.addTracksToLibraryPlaylist(
        service: self.libraryMutationsService,
        musicUserToken: musicUserToken,
        playlistId: playlistId,
        tracks: tracks
      )
    }

    // MARK: - Recommendations (ExpoBridgeRecommendations)

    AsyncFunction("getRecommendations") { (musicUserToken: String, ids: [String]?) -> [String: Any] in
      try await ExpoBridgeRecommendations.getRecommendations(
        service: self.recommendationsService,
        musicUserToken: musicUserToken,
        ids: ids
      )
    }

    AsyncFunction("getReplay") { (musicUserToken: String, year: Int?) -> [String: Any] in
      try await ExpoBridgeRecommendations.getReplay(
        service: self.recommendationsService,
        musicUserToken: musicUserToken,
        year: year
      )
    }
  }
}
