// PlaybackController.swift
// Encapsulates MusicKit player operations with caching for song info.

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

  private var activePlayer: ActiveMusicPlayer = .make(.application)

  var playerType: PlayerType {
    activePlayer.type
  }

  var state: MusicKit.MusicPlayer.State {
    activePlayer.state
  }

  var playbackTime: TimeInterval {
    get { activePlayer.playbackTime }
    set { activePlayer.playbackTime = newValue }
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

  // MARK: - Player Configuration

  /// Configures the audio session first, then commits any player-type switch.
  /// A failed audio session leave the selected backend unchanged.
  func configurePlayer(options: [String: Any]) throws -> [String: Any] {
    let mixWithOthers = options["mixWithOthers"] as? Bool ?? false
    let desiredPlayerType: PlayerType? = {
      guard let playerTypeRaw = options["playerType"] as? String else { return nil }
      return PlayerType(rawValue: playerTypeRaw)
    }()

    let audioSessionOptions = options["audioSession"] as? [String: Any] ?? [:]
    let normalizedAudioSession = try AudioSessionConfigurator.configure(
      mixWithOthers: mixWithOthers,
      options: audioSessionOptions
    )

    if let desiredPlayerType {
      setPlayerType(desiredPlayerType)
    }

    let normalizedMixWithOthers =
      (normalizedAudioSession["options"] as? [String] ?? []).contains("mixWithOthers")
    return [
      "mixWithOthers": normalizedMixWithOthers,
      "playerType": activePlayer.type.rawValue,
      "audioSession": normalizedAudioSession,
    ]
  }

  func setPlayerType(_ type: PlayerType) {
    guard activePlayer.type != type else { return }
    activePlayer = .make(type)
    clearSongCache()
    NotificationCenter.default.post(name: Self.playerTypeDidChangeNotification, object: nil)
  }

  // MARK: - Playback Controls

  func play() async throws {
    try await activePlayer.play()
  }

  func pause() {
    activePlayer.pause()
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
    try await activePlayer.skipToNext()
  }

  func skipToPrevious() async throws {
    try await activePlayer.skipToPrevious()
  }

  func restartCurrentEntry() {
    activePlayer.restartCurrentEntry()
  }

  func seek(to time: TimeInterval) {
    playbackTime = time
  }

  // MARK: - Queue Management

  func setQueue<T: PlayableMusicItem>(_ item: T) async throws {
    try await activePlayer.setQueue(item)
  }

  func setQueue<T: PlayableMusicItem>(_ items: [T], startingAt item: T) async throws {
    try await activePlayer.setQueue(items, startingAt: item)
  }

  func stateChangeStream() -> AsyncStream<Void> {
    activePlayer.stateChangeStream()
  }

  func queueChangeStream() -> AsyncStream<Void> {
    activePlayer.queueChangeStream()
  }

  // MARK: - Current Song Info

  /// Fetches detailed info for the current queue entry from the catalog.
  /// Uses caching to avoid redundant network calls when the song hasn't changed.
  func fetchCurrentSongInfo() async -> [String: Any]? {
    guard let entry = activePlayer.currentEntry else {
      clearSongCache()
      return nil
    }
    return await fetchCurrentSongInfo(for: entry)
  }

  private func fetchCurrentSongInfo(for entry: MusicKit.MusicPlayer.Queue.Entry) async -> [String: Any]? {
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
}
