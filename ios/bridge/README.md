# iOS bridge registration

Domain logic lives in `ExpoBridge*.swift` (service wrappers). **Expo module function
registration** lives in `ExpoBridgeRegistrations.swift`, which returns `[AnyDefinition]`
arrays merged through `ExpoAppleMusicModule._exposedDefinition()`.

Swift’s `ModuleDefinitionBuilder` cannot nest Android-style `register*Bridge` helpers
inside the result builder; `_exposedDefinition()` is the supported composition hook
(also used by the `@ExpoModule` macro).

`ExpoAppleMusicModuleDefinition.swift` should stay lifecycle-only (name, events, observe).

Use `ExpoBridge.asyncBridge { … }` in `ExpoBridge*.swift` wrappers so thrown errors
map through `AppleMusicBridgeError` consistently (see `ExpoBridgeHelpers.swift`).
