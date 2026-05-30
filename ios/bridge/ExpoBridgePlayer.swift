import Foundation

@available(iOS 16.0, *)
enum ExpoBridgePlayer {
  static func setPlaybackQueue(queueService: QueueService, itemId: String, type: String) async throws -> String {
    try await AppleMusicBridgeError.rethrow {
      try await queueService.setQueue(itemId: itemId, type: type)
      return "Track(s) added to queue"
    }
  }

  static func getCurrentState(
    playbackController: PlaybackController
  ) async -> [String: Any] {
    let state = playbackController.state
    let songInfo = await playbackController.fetchCurrentSongInfo()

    var result: [String: Any] = [
      "playbackRate": state.playbackRate,
      "playbackStatus": MusicItemMapper.describePlaybackStatus(state.playbackStatus),
      "playbackTime": playbackController.playbackTime,
    ]
    if let songInfo = songInfo {
      result["currentSong"] = songInfo
    }
    return result
  }

  static func playLibrarySong(
    queueService: QueueService,
    musicUserToken: String,
    songId: String
  ) async throws -> String {
    try await AppleMusicBridgeError.rethrow {
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
    try await AppleMusicBridgeError.rethrow {
      try await queueService.playLibraryPlaylist(
        musicUserToken: musicUserToken,
        playlistId: playlistId,
        startingAt: startingAt
      )
      return "Library playlist added to queue"
    }
  }
}
