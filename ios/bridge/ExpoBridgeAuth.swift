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
    return ["status": status.rawValue, "musicUserToken": musicUserToken]
  }

  static func checkSubscription(subscriptionService: SubscriptionService) async throws -> [String: Any] {
    do {
      let details = try await subscriptionService.checkSubscription()
      return details.toDictionary()
    } catch {
      if let subError = SubscriptionService.wrapSubscriptionError(error) {
        throw Exception(
          name: subError.code,
          description: subError.message,
          code: subError.code
        )
      }
      throw AppleMusicBridgeError.exception(from: error)
    }
  }

  static func getStorefront(musicUserToken: String) async throws -> [String: Any] {
    try await AppleMusicBridgeError.rethrow {
      let id = try await StorefrontService.getStorefrontId(musicUserToken: musicUserToken)
      return BridgeResponses.storefront(id: id)
    }
  }
}
