// PlaybackController.swift
// Encapsulates ApplicationMusicPlayer operations with caching for song info.

import AVFoundation
import Combine
import Foundation
import MusicKit

@available(iOS 16.0, *)
final class PlaybackController {

  // MARK: - Shared Instance

  static let shared = PlaybackController()

  // MARK: - Properties

  enum PlayerType: String {
    case application
    case system
  }

  static let playerTypeDidChangeNotification = Notification.Name("ExpoAppleMusicPlayerTypeDidChange")

  private let applicationPlayer = ApplicationMusicPlayer.shared
  private let systemPlayer = SystemMusicPlayer.shared
  private var selectedPlayerType: PlayerType = .application

  var playerType: PlayerType {
    selectedPlayerType
  }

  var state: MusicKit.MusicPlayer.State {
    switch selectedPlayerType {
    case .application:
      applicationPlayer.state
    case .system:
      systemPlayer.state
    }
  }

  var playbackTime: TimeInterval {
    get {
      switch selectedPlayerType {
      case .application:
        applicationPlayer.playbackTime
      case .system:
        systemPlayer.playbackTime
      }
    }
    set {
      switch selectedPlayerType {
      case .application:
        applicationPlayer.playbackTime = newValue
      case .system:
        systemPlayer.playbackTime = newValue
      }
    }
  }

  // MARK: - Song Info Cache

  private var cachedSongId: String?
  private var cachedSongInfo: [String: Any]?

  private lazy var catalogService = CatalogService()

  // MARK: - Initialization

  private init() {}

  /// Clears the song info cache (call when queue changes significantly)
  func clearSongCache() {
    cachedSongId = nil
    cachedSongInfo = nil
  }

  // MARK: - Audio Session Configuration

  func configurePlayer(options: [String: Any]) throws -> [String: Any] {
    let mixWithOthers = options["mixWithOthers"] as? Bool ?? false
    if let playerTypeRaw = options["playerType"] as? String,
       let playerType = PlayerType(rawValue: playerTypeRaw) {
      setPlayerType(playerType)
    }
    let audioSessionOptions = options["audioSession"] as? [String: Any] ?? [:]
    let normalizedAudioSession = try configureAudioSession(
      mixWithOthers: mixWithOthers,
      options: audioSessionOptions
    )
    let normalizedMixWithOthers =
      (normalizedAudioSession["options"] as? [String] ?? []).contains("mixWithOthers")
    return [
      "mixWithOthers": normalizedMixWithOthers,
      "playerType": selectedPlayerType.rawValue,
      "audioSession": normalizedAudioSession,
    ]
  }

  private func configureAudioSession(mixWithOthers: Bool, options: [String: Any]) throws -> [String: Any] {
    let session = AVAudioSession.sharedInstance()
    let categoryRaw = options["category"] as? String ?? "playback"
    let modeRaw = options["mode"] as? String ?? "default"
    let setActive = options["setActive"] as? Bool ?? true
    let parsedOptions = try parseAudioSessionOptions(options["options"], mixWithOthers: mixWithOthers)

    let category = try parseAudioSessionCategory(categoryRaw)
    let mode = try parseAudioSessionMode(modeRaw)

    try session.setCategory(category, mode: mode, options: parsedOptions)
    try session.setActive(setActive)
    return [
      "category": categoryRaw,
      "mode": modeRaw,
      "options": normalizedAudioSessionOptions(parsedOptions),
      "setActive": setActive,
    ]
  }

  func setPlayerType(_ type: PlayerType) {
    guard selectedPlayerType != type else { return }
    selectedPlayerType = type
    clearSongCache()
    NotificationCenter.default.post(name: Self.playerTypeDidChangeNotification, object: nil)
  }

  // MARK: - Playback Controls

  func play() async throws {
    switch selectedPlayerType {
    case .application:
      try await applicationPlayer.play()
    case .system:
      try await systemPlayer.play()
    }
  }

  func pause() {
    switch selectedPlayerType {
    case .application:
      applicationPlayer.pause()
    case .system:
      systemPlayer.pause()
    }
  }

  func togglePlayback() async throws {
    switch state.playbackStatus {
    case .playing:
      pause()
    case .paused, .stopped, .interrupted:
      try await play()
    default:
      try await play()
    }
  }

  func skipToNext() async throws {
    switch selectedPlayerType {
    case .application:
      try await applicationPlayer.skipToNextEntry()
    case .system:
      try await systemPlayer.skipToNextEntry()
    }
  }

  func skipToPrevious() async throws {
    switch selectedPlayerType {
    case .application:
      try await applicationPlayer.skipToPreviousEntry()
    case .system:
      try await systemPlayer.skipToPreviousEntry()
    }
  }

  func restartCurrentEntry() {
    switch selectedPlayerType {
    case .application:
      applicationPlayer.restartCurrentEntry()
    case .system:
      systemPlayer.restartCurrentEntry()
    }
  }

  func seek(to time: TimeInterval) {
    playbackTime = time
  }

  // MARK: - Queue Management

  func setQueue<T: PlayableMusicItem>(_ item: T) async throws {
    switch selectedPlayerType {
    case .application:
      applicationPlayer.queue = [item]
      try await applicationPlayer.prepareToPlay()
    case .system:
      systemPlayer.queue = [item]
      try await systemPlayer.prepareToPlay()
    }
  }

  func setQueue<T: PlayableMusicItem>(_ items: [T], startingAt item: T) async throws {
    switch selectedPlayerType {
    case .application:
      applicationPlayer.queue = ApplicationMusicPlayer.Queue(for: items, startingAt: item)
      try await applicationPlayer.prepareToPlay()
    case .system:
      systemPlayer.queue = SystemMusicPlayer.Queue(for: items, startingAt: item)
      try await systemPlayer.prepareToPlay()
    }
  }

  func stateChangeStream() -> AsyncStream<Void> {
    switch selectedPlayerType {
    case .application:
      stream(for: applicationPlayer.state.objectWillChange)
    case .system:
      stream(for: systemPlayer.state.objectWillChange)
    }
  }

  func queueChangeStream() -> AsyncStream<Void> {
    switch selectedPlayerType {
    case .application:
      stream(for: applicationPlayer.queue.objectWillChange)
    case .system:
      stream(for: systemPlayer.queue.objectWillChange)
    }
  }

  // MARK: - Current Song Info

  /// Fetches detailed info for the current queue entry from the catalog.
  /// Uses caching to avoid redundant network calls when the song hasn't changed.
  func fetchCurrentSongInfo() async -> [String: Any]? {
    let entry: Any?
    switch selectedPlayerType {
    case .application:
      entry = applicationPlayer.queue.currentEntry
    case .system:
      entry = systemPlayer.queue.currentEntry
    }

    guard let entry else {
      // No current entry - clear cache and return nil
      clearSongCache()
      return nil
    }

    // ApplicationMusicPlayer.Queue.Entry and SystemMusicPlayer.Queue.Entry are
    // the same underlying MusicPlayer.Queue.Entry, so one cast covers both players.
    if let queueEntry = entry as? MusicKit.MusicPlayer.Queue.Entry {
      return await fetchCurrentSongInfo(for: queueEntry)
    }
    return cachedSongInfo
  }

  private func fetchCurrentSongInfo(for entry: MusicKit.MusicPlayer.Queue.Entry) async -> [String: Any]? {
    // entry.item is optional on the base MusicPlayer.Queue.Entry — unwrap once.
    guard let item = entry.item else { return cachedSongInfo }
    let currentId = currentQueueEntryId(item)
    guard let currentId else { return cachedSongInfo }
    if currentId == cachedSongId, let cached = cachedSongInfo { return cached }
    let songInfo = await queueEntrySongInfo(item)
    if let songInfo {
      cachedSongId = currentId
      cachedSongInfo = songInfo
    }
    return songInfo ?? cachedSongInfo
  }

  private func currentQueueEntryId(_ item: MusicKit.MusicPlayer.Queue.Entry.Item) -> String? {
    switch item {
    case .song(let song):
      let idString = String(describing: song.id)
      return idString.isEmpty ? nil : idString
    case .musicVideo(let musicVideo):
      let idString = String(describing: musicVideo.id)
      return idString.isEmpty ? nil : idString
    default:
      return nil
    }
  }

  private func queueEntrySongInfo(_ item: MusicKit.MusicPlayer.Queue.Entry.Item) async -> [String: Any]? {
    switch item {
    case .song(let song):
      return await songInfoForQueueEntry(song)
    case .musicVideo(let musicVideo):
      return await musicVideoInfoForQueueEntry(musicVideo)
    default:
      return nil
    }
  }

  private func songInfoForQueueEntry(_ song: Song) async -> [String: Any] {
    let mapped = MusicItemMapper.map(song)
    if hasDisplayMetadata(mapped) {
      return mapped
    }
    return await fetchSongDetailsFallback(song.id) ?? mapped
  }

  private func musicVideoInfoForQueueEntry(_ musicVideo: MusicVideo) async -> [String: Any] {
    let mapped = MusicItemMapper.map(musicVideo)
    if hasDisplayMetadata(mapped) {
      return mapped
    }
    return await fetchMusicVideoDetailsFallback(musicVideo.id) ?? mapped
  }

  private func hasDisplayMetadata(_ mapped: [String: Any]) -> Bool {
    let title = mapped["title"] as? String ?? ""
    return !title.isEmpty
  }

  private func fetchSongDetailsFallback(_ id: MusicItemID) async -> [String: Any]? {
    guard let song = try? await catalogService.fetchSong(id: id) else { return nil }
    return MusicItemMapper.map(song)
  }

  private func fetchMusicVideoDetailsFallback(_ id: MusicItemID) async -> [String: Any]? {
    guard let video = try? await catalogService.fetchMusicVideo(id: id) else { return nil }
    return MusicItemMapper.map(video)
  }

  private func stream<P: Publisher>(for publisher: P) -> AsyncStream<Void> where P.Failure == Never {
    AsyncStream<Void> { continuation in
      let cancellable = publisher.sink { _ in
        continuation.yield()
      }
      continuation.onTermination = { _ in
        cancellable.cancel()
      }
    }
  }

  private func parseAudioSessionCategory(_ value: String) throws -> AVAudioSession.Category {
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
      throw NSError(
        domain: "AVAudioSession",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Unsupported audio session category: \(value)"]
      )
    }
  }

  private func parseAudioSessionMode(_ value: String) throws -> AVAudioSession.Mode {
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
      throw NSError(
        domain: "AVAudioSession",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Unsupported audio session mode: \(value)"]
      )
    }
  }

  private func parseAudioSessionOptions(_ raw: Any?, mixWithOthers: Bool) throws -> AVAudioSession.CategoryOptions {
    let names: [String]
    if let stringNames = raw as? [String] {
      names = stringNames
    } else if let anyNames = raw as? [Any] {
      names = try anyNames.enumerated().map { index, value in
        guard let option = value as? String else {
          throw NSError(
            domain: "AVAudioSession",
            code: -1,
            userInfo: [
              NSLocalizedDescriptionKey:
                "Audio session option at index \(index) must be a string, got value \(String(describing: value)) of type \(String(describing: type(of: value)))."
            ]
          )
        }
        return option
      }
    } else if raw == nil {
      names = []
    } else {
      throw NSError(
        domain: "AVAudioSession",
        code: -1,
        userInfo: [
          NSLocalizedDescriptionKey:
            "Audio session options must be an array, got value \(String(describing: raw)) of type \(String(describing: type(of: raw as Any)))."
        ]
      )
    }
    var parsed: AVAudioSession.CategoryOptions = []
    for option in names {
      parsed.formUnion(try parseAudioSessionOption(option))
    }
    if mixWithOthers {
      parsed.formUnion([.mixWithOthers, .duckOthers])
    }
    return parsed
  }

  private func parseAudioSessionOption(_ value: String) throws -> AVAudioSession.CategoryOptions {
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
      throw NSError(
        domain: "AVAudioSession",
        code: -1,
        userInfo: [NSLocalizedDescriptionKey: "Unsupported audio session option: \(value)"]
      )
    }
  }

  private func normalizedAudioSessionOptions(_ options: AVAudioSession.CategoryOptions) -> [String] {
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
}
