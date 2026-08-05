// AudioSessionConfigurator.swift
// Parses JS audio-session options and applies them to AVAudioSession.

import AVFoundation
import Foundation

@available(iOS 16.0, *)
enum AudioSessionConfigurator {
  static func configure(mixWithOthers: Bool, options: [String: Any]) throws -> [String: Any] {
    let session = AVAudioSession.sharedInstance()
    let categoryRaw = options["category"] as? String ?? "playback"
    let modeRaw = options["mode"] as? String ?? "default"
    let setActive = options["setActive"] as? Bool ?? true
    let parsedOptions = try parseOptions(options["options"], mixWithOthers: mixWithOthers)

    let category = try parseCategory(categoryRaw)
    let mode = try parseMode(modeRaw)

    try session.setCategory(category, mode: mode, options: parsedOptions)
    try session.setActive(setActive)
    return [
      "category": categoryRaw,
      "mode": modeRaw,
      "options": normalizedOptionNames(parsedOptions),
      "setActive": setActive,
    ]
  }

  private static func parseCategory(_ value: String) throws -> AVAudioSession.Category {
    switch value {
    case "ambient":
      return .ambient
    case "soloAmbient":
      return .soloAmbient
    case "playback":
      return .playback
    case "record":
      return .record
    case "playAndRecord":
      return .playAndRecord
    case "multiRoute":
      return .multiRoute
    default:
      throw audioSessionError("Unsupported audio session category: \(value)")
    }
  }

  private static func parseMode(_ value: String) throws -> AVAudioSession.Mode {
    switch value {
    case "default":
      return .default
    case "voiceChat":
      return .voiceChat
    case "videoChat":
      return .videoChat
    case "gameChat":
      return .gameChat
    case "videoRecording":
      return .videoRecording
    case "measurement":
      return .measurement
    case "moviePlayback":
      return .moviePlayback
    case "spokenAudio":
      return .spokenAudio
    case "voicePrompt":
      return .voicePrompt
    default:
      throw audioSessionError("Unsupported audio session mode: \(value)")
    }
  }

  private static func parseOptions(_ raw: Any?, mixWithOthers: Bool) throws -> AVAudioSession.CategoryOptions {
    let names: [String]
    if let stringNames = raw as? [String] {
      names = stringNames
    } else if let anyNames = raw as? [Any] {
      names = try anyNames.enumerated().map { index, value in
        guard let option = value as? String else {
          throw audioSessionError(
            "Audio session option at index \(index) must be a string, got value \(String(describing: value)) of type \(String(describing: type(of: value)))."
          )
        }
        return option
      }
    } else if raw == nil {
      names = []
    } else {
      throw audioSessionError(
        "Audio session options must be an array, got value \(String(describing: raw)) of type \(String(describing: type(of: raw as Any)))."
      )
    }

    var parsed: AVAudioSession.CategoryOptions = []
    for option in names {
      parsed.formUnion(try parseOption(option))
    }
    if mixWithOthers {
      parsed.formUnion([.mixWithOthers, .duckOthers])
    }
    return parsed
  }

  private static func parseOption(_ value: String) throws -> AVAudioSession.CategoryOptions {
    switch value {
    case "mixWithOthers":
      return .mixWithOthers
    case "duckOthers":
      return .duckOthers
    case "interruptSpokenAudioAndMixWithOthers":
      return .interruptSpokenAudioAndMixWithOthers
    case "allowBluetooth":
      return .allowBluetooth
    case "allowBluetoothA2DP":
      return .allowBluetoothA2DP
    case "allowAirPlay":
      return .allowAirPlay
    case "defaultToSpeaker":
      return .defaultToSpeaker
    case "overrideMutedMicrophoneInterruption":
      return .overrideMutedMicrophoneInterruption
    default:
      throw audioSessionError("Unsupported audio session option: \(value)")
    }
  }

  private static func normalizedOptionNames(_ options: AVAudioSession.CategoryOptions) -> [String] {
    var names: [String] = []
    if options.contains(.mixWithOthers) { names.append("mixWithOthers") }
    if options.contains(.duckOthers) { names.append("duckOthers") }
    if options.contains(.interruptSpokenAudioAndMixWithOthers) {
      names.append("interruptSpokenAudioAndMixWithOthers")
    }
    if options.contains(.allowBluetooth) { names.append("allowBluetooth") }
    if options.contains(.allowBluetoothA2DP) { names.append("allowBluetoothA2DP") }
    if options.contains(.allowAirPlay) { names.append("allowAirPlay") }
    if options.contains(.defaultToSpeaker) { names.append("defaultToSpeaker") }
    if options.contains(.overrideMutedMicrophoneInterruption) {
      names.append("overrideMutedMicrophoneInterruption")
    }
    return names
  }

  private static func audioSessionError(_ message: String) -> NSError {
    NSError(
      domain: "AVAudioSession",
      code: -1,
      userInfo: [NSLocalizedDescriptionKey: message]
    )
  }
}
