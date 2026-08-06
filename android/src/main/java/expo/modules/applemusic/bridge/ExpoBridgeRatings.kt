package expo.modules.applemusic.bridge

import expo.modules.applemusic.RatingsRestClient
import expo.modules.kotlin.functions.Coroutine
import expo.modules.kotlin.modules.ModuleDefinitionBuilder

internal fun ModuleDefinitionBuilder.registerRatingsBridge(
  ratings: () -> RatingsRestClient,
) {
  AsyncFunction("getRating") Coroutine { musicUserToken: String, resourceType: String, id: String ->
    ratings().getRating(musicUserToken, resourceType, id)
  }

  AsyncFunction("setRating") Coroutine { musicUserToken: String, resourceType: String, id: String, value: Int ->
    ratings().setRating(musicUserToken, resourceType, id, value)
  }

  AsyncFunction("clearRating") Coroutine { musicUserToken: String, resourceType: String, id: String ->
    ratings().clearRating(musicUserToken, resourceType, id)
  }

  AsyncFunction("addToFavorites") Coroutine { musicUserToken: String, resourceIds: Map<String, List<String>> ->
    ratings().addToFavorites(musicUserToken, resourceIds)
  }

  AsyncFunction("removeFromFavorites") Coroutine { musicUserToken: String, resourceIds: Map<String, List<String>> ->
    ratings().removeFromFavorites(musicUserToken, resourceIds)
  }
}
