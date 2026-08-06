// SubscriptionService.swift
// Handles Apple Music authorization and subscription status checks.

import Foundation
import MusicKit
import StoreKit

@available(iOS 16.0, *)
final class SubscriptionService {

  // MARK: - Authorization

  enum AuthorizationStatus: String {
    case authorized
    case denied
    case notDetermined
    case restricted
    case unknown
  }

  func requestAuthorization() async -> AuthorizationStatus {
    await withCheckedContinuation { continuation in
      SKCloudServiceController.requestAuthorization { status in
        let result: AuthorizationStatus
        switch status {
        case .authorized: result = .authorized
        case .denied: result = .denied
        case .notDetermined: result = .notDetermined
        case .restricted: result = .restricted
        @unknown default: result = .unknown
        }
        continuation.resume(returning: result)
      }
    }
  }

  /// Fetches a music user token when a developer JWT is available (not persisted by the module).
  func fetchMusicUserToken(developerToken: String) async -> String? {
    guard !developerToken.isEmpty else { return nil }
    return await withCheckedContinuation { continuation in
      SKCloudServiceController().requestUserToken(forDeveloperToken: developerToken) { token, _ in
        if let token, !token.isEmpty {
          continuation.resume(returning: token)
        } else {
          continuation.resume(returning: nil)
        }
      }
    }
  }

  // MARK: - Subscription Check

  struct SubscriptionDetails {
    let canPlayCatalogContent: Bool
    let canBecomeSubscriber: Bool
    let hasCloudLibraryEnabled: Bool
    let isMusicCatalogSubscriptionEligible: Bool

  }

  func checkSubscription() async throws -> SubscriptionDetails {
    let subscription = try await MusicSubscription.current
    return SubscriptionDetails(
      canPlayCatalogContent: subscription.canPlayCatalogContent,
      canBecomeSubscriber: subscription.canBecomeSubscriber,
      hasCloudLibraryEnabled: subscription.hasCloudLibraryEnabled,
      isMusicCatalogSubscriptionEligible: subscription.canBecomeSubscriber
    )
  }
}

// MARK: - Subscription Error Handling

@available(iOS 16.0, *)
extension SubscriptionService {

  struct SubscriptionError: LocalizedError {
    let code: String
    let message: String
    let failureReason: String?
    let recoverySuggestion: String?
    let helpAnchor: String?

    var errorDescription: String? { message }

    func toNSError() -> NSError {
      var userInfo: [String: Any] = [NSLocalizedDescriptionKey: message]
      if let reason = failureReason {
        userInfo[NSLocalizedFailureReasonErrorKey] = reason
      }
      if let suggestion = recoverySuggestion {
        userInfo[NSLocalizedRecoverySuggestionErrorKey] = suggestion
      }
      if let anchor = helpAnchor {
        userInfo[NSHelpAnchorErrorKey] = anchor
      }
      return NSError(domain: "MusicSubscription", code: 0, userInfo: userInfo)
    }
  }

  static func wrapSubscriptionError(_ error: Error) -> SubscriptionError? {
    guard let subError = error as? MusicSubscription.Error else { return nil }
    return SubscriptionError(
      code: subError.rawValue,
      message: subError.localizedDescription,
      failureReason: subError.failureReason,
      recoverySuggestion: subError.recoverySuggestion,
      helpAnchor: subError.helpAnchor
    )
  }
}
