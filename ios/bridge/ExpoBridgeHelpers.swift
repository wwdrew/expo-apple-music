import Foundation

/// Shared helpers for `ExpoBridge*.swift` service wrappers.
/// Prefer `asyncBridge` over calling `AppleMusicBridgeError.rethrow` directly so
/// error mapping stays uniform at the bridge boundary.
@available(iOS 16.0, *)
enum ExpoBridge {
  static func asyncBridge<T>(_ operation: () async throws -> T) async throws -> T {
    try await AppleMusicBridgeError.rethrow(operation)
  }
}
