package expo.modules.applemusic

/** Standard bridge response envelopes (keys match iOS and TypeScript). */
internal object BridgeResponses {
  fun storefront(id: String): Map<String, Any?> = mapOf("id" to id)

  fun authorization(status: String, musicUserToken: String?): Map<String, Any?> =
    mapOf("status" to status, "musicUserToken" to musicUserToken)

  fun subscription(
    canPlayCatalogContent: Boolean,
    canBecomeSubscriber: Boolean,
    hasCloudLibraryEnabled: Boolean,
    isMusicCatalogSubscriptionEligible: Boolean,
  ): Map<String, Any?> =
    mapOf(
      "canPlayCatalogContent" to canPlayCatalogContent,
      "canBecomeSubscriber" to canBecomeSubscriber,
      "hasCloudLibraryEnabled" to hasCloudLibraryEnabled,
      "isMusicCatalogSubscriptionEligible" to isMusicCatalogSubscriptionEligible,
    )

  fun playbackState(
    playbackRate: Double,
    playbackStatus: String,
    playbackTime: Double,
    currentSong: Map<String, Any?>?,
  ): Map<String, Any?> =
    buildMap {
      put("playbackRate", playbackRate)
      put("playbackStatus", playbackStatus)
      put("playbackTime", playbackTime)
      if (currentSong != null) put("currentSong", currentSong)
    }

  fun catalogSearch(result: AndroidCatalogService.SearchResult): Map<String, Any?> =
    mapOf(
      "songs" to result.songs,
      "albums" to result.albums,
      "artists" to result.artists,
      "playlists" to result.playlists,
      "stations" to result.stations,
      "musicVideos" to result.musicVideos,
    )

  fun catalogCharts(result: AndroidCatalogService.ChartsResult): Map<String, Any?> =
    mapOf(
      "songs" to result.songs,
      "albums" to result.albums,
      "playlists" to result.playlists,
      "musicVideos" to result.musicVideos,
    )

  fun songs(items: List<Map<String, Any?>>): Map<String, Any?> = mapOf("songs" to items)

  fun albums(items: List<Map<String, Any?>>): Map<String, Any?> = mapOf("albums" to items)

  fun artists(items: List<Map<String, Any?>>): Map<String, Any?> = mapOf("artists" to items)

  fun playlists(items: List<Map<String, Any?>>): Map<String, Any?> = mapOf("playlists" to items)

  fun musicVideos(items: List<Map<String, Any?>>): Map<String, Any?> = mapOf("musicVideos" to items)

  fun librarySearch(result: AndroidLibraryService.LibrarySearchResult): Map<String, Any?> =
    mapOf(
      "songs" to result.songs,
      "albums" to result.albums,
      "artists" to result.artists,
      "playlists" to result.playlists,
      "musicVideos" to result.musicVideos,
    )

  fun stations(items: List<Map<String, Any?>>): Map<String, Any?> = mapOf("stations" to items)

  fun recentlyPlayedResources(items: List<Map<String, Any?>>): Map<String, Any?> =
    mapOf("recentlyPlayedItems" to items)

  fun recentItems(items: List<Map<String, Any?>>): Map<String, Any?> = mapOf("items" to items)

  fun recommendations(items: List<Map<String, Any?>>): Map<String, Any?> =
    mapOf("recommendations" to items)

  fun replaySummaries(items: List<Map<String, Any?>>): Map<String, Any?> = mapOf("summaries" to items)
}
