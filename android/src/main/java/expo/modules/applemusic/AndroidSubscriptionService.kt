package expo.modules.applemusic

import android.content.Context

/**
 * Approximates iOS [MusicSubscription] fields — there is no equivalent on Android.
 * Library probe returns false only for HTTP 403; other failures propagate.
 */
internal class AndroidSubscriptionService(
  private val library: LibraryRestClient,
) {
  constructor(context: Context) : this(AppleMusicRestStack.create(context).library)

  suspend fun checkSubscription(musicUserToken: String): Map<String, Any?> {
    val libraryOk = library.probeLibraryAccess(musicUserToken)
    val canPlay = libraryOk

    return BridgeResponses.subscription(
      canPlayCatalogContent = canPlay,
      canBecomeSubscriber = false,
      hasCloudLibraryEnabled = libraryOk,
      isMusicCatalogSubscriptionEligible = false,
    )
  }
}
