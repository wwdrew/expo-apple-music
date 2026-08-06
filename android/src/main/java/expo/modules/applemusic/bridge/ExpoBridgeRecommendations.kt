package expo.modules.applemusic.bridge

import expo.modules.applemusic.BridgeResponses
import expo.modules.applemusic.RecommendationsRestClient
import expo.modules.kotlin.functions.Coroutine
import expo.modules.kotlin.modules.ModuleDefinitionBuilder

internal fun ModuleDefinitionBuilder.registerRecommendationsBridge(
  recommendations: () -> RecommendationsRestClient,
) {
  AsyncFunction("getRecommendations") Coroutine { musicUserToken: String, ids: List<String>? ->
    BridgeResponses.recommendations(recommendations().getRecommendations(musicUserToken, ids))
  }

  AsyncFunction("getReplay") Coroutine { musicUserToken: String, year: Int? ->
    BridgeResponses.replaySummaries(recommendations().getReplay(musicUserToken, year))
  }
}
