import Foundation

@available(iOS 16.0, *)
enum ExpoBridgePlayer {
  static func setPlaybackQueue(queueService: QueueService, itemId: String, type: String) async throws -> String {
    try await ExpoBridge.asyncBridge {
      try await queueService.setQueue(itemId: itemId, type: type)
      return "Track(s) added to queue"
    }
  }

  static func getCurrentState(
    playbackController: PlaybackController
  ) async -> [String: Any] {
    let state = playbackController.state
    let songInfo = await playbackController.fetchCurrentSongInfo()
    return BridgeResponses.playbackState(
      playbackRate: state.playbackRate,
      playbackStatus: MusicItemMapper.describePlaybackStatus(state.playbackStatus),
      playbackTime: playbackController.playbackTime,
      currentSong: songInfo
    )
  }

  static func playLibrarySong(
    queueService: QueueService,
    musicUserToken: String,
    songId: String
  ) async throws -> String {
    try await ExpoBridge.asyncBridge {
      try await queueService.playLibrarySong(musicUserToken: musicUserToken, songId: songId)
      return "Library song added to queue"
    }
  }

  static func playLibraryPlaylist(
    queueService: QueueService,
    musicUserToken: String,
    playlistId: String,
    startingAt: Int
  ) async throws -> String {
    try await ExpoBridge.asyncBridge {
      try await queueService.playLibraryPlaylist(
        musicUserToken: musicUserToken,
        playlistId: playlistId,
        startingAt: startingAt
      )
      return "Library playlist added to queue"
    }
  }
}
