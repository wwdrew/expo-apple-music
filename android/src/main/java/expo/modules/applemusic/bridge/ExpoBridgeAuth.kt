package expo.modules.applemusic.bridge

import android.content.Context
import expo.modules.applemusic.AndroidDeveloperToken
import expo.modules.applemusic.AndroidPlaybackController
import expo.modules.applemusic.AndroidSubscriptionService
import expo.modules.applemusic.BridgeResponses
import expo.modules.applemusic.MusicKitAuthInput
import expo.modules.applemusic.MusicKitAuthOutput
import expo.modules.applemusic.MusicKitAuthStorage
import expo.modules.kotlin.activityresult.AppContextActivityResultLauncher
import expo.modules.kotlin.functions.Coroutine
import expo.modules.kotlin.modules.ModuleDefinitionBuilder

internal fun ModuleDefinitionBuilder.registerAuthBridge(
  reactContext: () -> Context,
  authLauncher: () -> AppContextActivityResultLauncher<MusicKitAuthInput, MusicKitAuthOutput>,
  subscriptionService: () -> AndroidSubscriptionService,
  libraryService: () -> expo.modules.applemusic.AndroidLibraryService,
) {
  AsyncFunction("setDeveloperToken") { token: String ->
    val trimmed = token.trim()
    require(trimmed.isNotEmpty()) { "Developer token must not be empty" }
    val context = reactContext()
    MusicKitAuthStorage.saveDeveloperToken(context, trimmed)
    AndroidPlaybackController.getInstance(context).attachPendingListenersAfterDeveloperTokenStored()
  }

  AsyncFunction("authorization") Coroutine {
    developerToken: String?,
    startScreenMessage: String?,
    hideStartScreen: Boolean?,
  ->
    val context = reactContext()
    val token = AndroidDeveloperToken.require(developerToken)
    MusicKitAuthStorage.saveDeveloperToken(context, token)
    AndroidPlaybackController.getInstance(context).attachPendingListenersAfterDeveloperTokenStored()
    val message = startScreenMessage?.trim()?.takeIf { it.isNotEmpty() }
    val result =
      authLauncher().launch(
        MusicKitAuthInput(
          developerToken = token,
          startScreenMessage = message,
          hideStartScreen = hideStartScreen ?: false,
        ),
      )

    if (result.status == "authorized") {
      result.musicUserToken?.let { userToken ->
        MusicKitAuthStorage.saveMusicUserToken(context, userToken)
        AndroidPlaybackController.getInstance(context).applyMusicUserToken(userToken)
      }
      AndroidPlaybackController.warmUp(context)
    }

    BridgeResponses.authorization(result.status, result.musicUserToken)
  }

  AsyncFunction("checkSubscription") Coroutine { musicUserToken: String ->
    subscriptionService().checkSubscription(musicUserToken)
  }

  AsyncFunction("getStorefront") Coroutine { musicUserToken: String ->
    BridgeResponses.storefront(libraryService().getStorefrontId(musicUserToken))
  }
}
