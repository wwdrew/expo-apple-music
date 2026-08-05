// ActiveMusicPlayer.swift
// Routes MusicKit playback through ApplicationMusicPlayer or SystemMusicPlayer.

import Combine
import Foundation
import MusicKit

@available(iOS 16.0, *)
enum ActiveMusicPlayer {
  case application(ApplicationMusicPlayer)
  case system(SystemMusicPlayer)

  static func make(_ type: PlaybackController.PlayerType) -> ActiveMusicPlayer {
    switch type {
    case .application:
      return .application(.shared)
    case .system:
      return .system(.shared)
    }
  }

  var type: PlaybackController.PlayerType {
    switch self {
    case .application:
      return .application
    case .system:
      return .system
    }
  }

  var state: MusicKit.MusicPlayer.State {
    switch self {
    case .application(let player):
      return player.state
    case .system(let player):
      return player.state
    }
  }

  var playbackTime: TimeInterval {
    get {
      switch self {
      case .application(let player):
        return player.playbackTime
      case .system(let player):
        return player.playbackTime
      }
    }
    nonmutating set {
      switch self {
      case .application(let player):
        player.playbackTime = newValue
      case .system(let player):
        player.playbackTime = newValue
      }
    }
  }

  var currentEntry: MusicKit.MusicPlayer.Queue.Entry? {
    switch self {
    case .application(let player):
      return player.queue.currentEntry
    case .system(let player):
      return player.queue.currentEntry
    }
  }

  func play() async throws {
    switch self {
    case .application(let player):
      try await player.play()
    case .system(let player):
      try await player.play()
    }
  }

  func pause() {
    switch self {
    case .application(let player):
      player.pause()
    case .system(let player):
      player.pause()
    }
  }

  func skipToNext() async throws {
    switch self {
    case .application(let player):
      try await player.skipToNextEntry()
    case .system(let player):
      try await player.skipToNextEntry()
    }
  }

  func skipToPrevious() async throws {
    switch self {
    case .application(let player):
      try await player.skipToPreviousEntry()
    case .system(let player):
      try await player.skipToPreviousEntry()
    }
  }

  func restartCurrentEntry() {
    switch self {
    case .application(let player):
      player.restartCurrentEntry()
    case .system(let player):
      player.restartCurrentEntry()
    }
  }

  func setQueue<T: PlayableMusicItem>(_ item: T) async throws {
    switch self {
    case .application(let player):
      player.queue = [item]
      try await player.prepareToPlay()
    case .system(let player):
      player.queue = [item]
      try await player.prepareToPlay()
    }
  }

  func setQueue<T: PlayableMusicItem>(_ items: [T], startingAt item: T) async throws {
    switch self {
    case .application(let player):
      player.queue = ApplicationMusicPlayer.Queue(for: items, startingAt: item)
      try await player.prepareToPlay()
    case .system(let player):
      player.queue = SystemMusicPlayer.Queue(for: items, startingAt: item)
      try await player.prepareToPlay()
    }
  }

  func stateChangeStream() -> AsyncStream<Void> {
    switch self {
    case .application(let player):
      return stream(for: player.state.objectWillChange)
    case .system(let player):
      return stream(for: player.state.objectWillChange)
    }
  }

  func queueChangeStream() -> AsyncStream<Void> {
    switch self {
    case .application(let player):
      return stream(for: player.queue.objectWillChange)
    case .system(let player):
      return stream(for: player.queue.objectWillChange)
    }
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
}
