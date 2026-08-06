import ExpoModulesCore
import Foundation

@available(iOS 16.0, *)
enum ExpoBridgeAuth {
  static func authorization(
    subscriptionService: SubscriptionService,
    developerToken: String?,
    startScreenMessage: String?,
    hideStartScreen: Bool?
  ) async -> [String: Any?] {
    if let token = developerToken, !token.isEmpty {
      MusicKitAuthStorage.saveDeveloperToken(token)
    }
    let status = await subscriptionService.requestAuthorization()
    var musicUserToken: String? = nil
    if status == .authorized, let token = developerToken, !token.isEmpty {
      musicUserToken = await subscriptionService.fetchMusicUserToken(developerToken: token)
    }
    return BridgeResponses.authorization(status: status.rawValue, musicUserToken: musicUserToken)
  }

  static func checkSubscription(subscriptionService: SubscriptionService) async throws -> [String: Any] {
    try await ExpoBridge.asyncBridge {
      let details = try await subscriptionService.checkSubscription()
      return BridgeResponses.subscription(
        canPlayCatalogContent: details.canPlayCatalogContent,
        canBecomeSubscriber: details.canBecomeSubscriber,
        hasCloudLibraryEnabled: details.hasCloudLibraryEnabled,
        isMusicCatalogSubscriptionEligible: details.isMusicCatalogSubscriptionEligible
      )
    }
  }

  static func getStorefront(musicUserToken: String) async throws -> [String: Any] {
    try await ExpoBridge.asyncBridge {
      let id = try await StorefrontService.getStorefrontId(musicUserToken: musicUserToken)
      return BridgeResponses.storefront(id: id)
    }
  }
}
