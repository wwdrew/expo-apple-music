// AppleMusicErrorCodes.swift
// Bridge rejection codes — keep in sync with src/constants/apple-music-error-codes.ts and docs/ERROR_CODES.md.

import Foundation

@available(iOS 16.0, *)
enum AppleMusicErrorCodes {
  static let error = "ERROR"
  static let permissionDenied = "permissionDenied"
  static let playbackError = "PLAYBACK_ERROR"
  static let unsupportedPlatform = "UNSUPPORTED_PLATFORM"
}
