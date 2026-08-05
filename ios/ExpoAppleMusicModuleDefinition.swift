import ExpoModulesCore

@available(iOS 16.0, *)
extension ExpoAppleMusicModule {
  /// Lifecycle + events only. Bridge `AsyncFunction`s are registered via
  /// `_exposedDefinition()` → `ExpoBridgeRegistrations` (see `ios/bridge/`).
  @ModuleDefinitionBuilder
  public func definition() -> ModuleDefinition {
    Name("ExpoAppleMusic")

    Events(
      "onPlaybackStateChange",
      "onCurrentSongChange",
      "onPlaybackTimeUpdate",
      "onPlaybackError"
    )

    OnStartObserving {
      let observer = PlaybackObserver(playbackController: self.playbackController)
      observer.delegate = self
      observer.startObserving()
      self.playbackObserver = observer
    }

    OnStopObserving {
      self.playbackObserver?.stopObserving()
      self.playbackObserver = nil
    }
  }

  /// Merged by `ModuleHolder` ahead of `definition()` — same extension point as `@ExpoModule`.
  public func _exposedDefinition() -> [AnyDefinition] {
    ExpoBridgeRegistrations.all(module: self)
  }
}
