package expo.modules.applemusic.bridge

import expo.modules.applemusic.BridgeResponses
import expo.modules.applemusic.HistoryRestClient
import expo.modules.applemusic.PaginationOptions
import expo.modules.kotlin.functions.Coroutine
import expo.modules.kotlin.modules.ModuleDefinitionBuilder

internal fun ModuleDefinitionBuilder.registerHistoryBridge(
  history: () -> HistoryRestClient,
) {
  AsyncFunction("getRecentlyPlayedResources") Coroutine { musicUserToken: String ->
    BridgeResponses.recentlyPlayedResources(history().getRecentlyPlayed(musicUserToken))
  }

  AsyncFunction("getRecentlyPlayedTracks") Coroutine { musicUserToken: String, options: Map<String, Any?> ->
    val pagination = PaginationOptions.fromMap(options)
    BridgeResponses.songs(history().getRecentlyPlayedTracks(musicUserToken, pagination.limit))
  }

  AsyncFunction("getHeavyRotation") Coroutine { musicUserToken: String, options: Map<String, Any?> ->
    val pagination = PaginationOptions.fromMap(options)
    BridgeResponses.recentItems(history().getHeavyRotation(musicUserToken, pagination.limit))
  }

  AsyncFunction("getRecentlyPlayedStations") Coroutine { musicUserToken: String, options: Map<String, Any?> ->
    val pagination = PaginationOptions.fromMap(options)
    BridgeResponses.stations(history().getRecentlyPlayedStations(musicUserToken, pagination.limit))
  }

  AsyncFunction("getRecentlyAdded") Coroutine { musicUserToken: String, options: Map<String, Any?> ->
    val pagination = PaginationOptions.fromMap(options)
    BridgeResponses.recentItems(history().getRecentlyAdded(musicUserToken, pagination.limit, pagination.offset))
  }
}
