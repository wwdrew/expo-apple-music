// BridgeMapperHelpers.swift
// Pure bridge mapping helpers shared by MusicItemMapper (native) and RestJsonMapper (REST).
// No MusicKit types — testable in BridgeContractPackage on macOS.

import Foundation

enum BridgeMapperHelpers {

  /// MusicKit `duration` is seconds; bridge uses milliseconds (matches `durationInMillis` from REST).
  static func durationMillis(fromSeconds seconds: TimeInterval?) -> Int {
    Int((seconds ?? 0) * 1000)
  }

  /// Playback id from MusicKit-decoded or REST `playParams` (`id` / `catalogId`).
  static func catalogPlaybackId(fromPlayParams playParams: [String: Any]?) -> String? {
    guard let playParams else { return nil }
    if let id = playParams["id"] as? String, !id.isEmpty { return id }
    if let catalogId = playParams["catalogId"] as? String, !catalogId.isEmpty { return catalogId }
    return nil
  }
}
