# Android — full iOS parity (implementation plan)

Single handoff to implement **every** `ExpoAppleMusic` native method on Android so the existing TypeScript API works unchanged. Read [CONTEXT.md](../CONTEXT.md) and [docs/AUTH.md](./AUTH.md).

---

## Will Android call the REST API from native code?

**Yes.** That is the intended architecture.

| Layer | iOS (today) | Android (target) |
|-------|-------------|------------------|
| JavaScript | `Auth` / `MusicKit` / `Player` — unchanged | Same modules, same types |
| Bridge | `ExpoAppleMusicModule` | Same module name and method names |
| Native | Swift calls **MusicKit** / `SKCloudServiceController` | Kotlin calls **Apple Music API (HTTPS)** + **playback AAR** + **auth AAR** |
| Apple | OS frameworks | `api.music.apple.com` + `mediaplayback-release-1.1.1.aar` + `musickitauth` |

**JavaScript must not** call Apple Music API directly for these features. Native Kotlin will:

1. Load `AuthenticatedSession` (tokens from `MusicKitAuthStorage` after `authorize()`)
2. Resolve **storefront** (e.g. `GET /v1/me/storefront`)
3. Perform REST requests with headers:
   - `Authorization: Bearer {developerToken}`
   - `Music-User-Token: {musicUserToken}`
4. Parse JSON and map to the **same dictionaries** iOS already returns (`[String: Any]` / maps)
5. Return through Expo bridge to existing TS types

Playback queue setup uses the **playback AAR** (`MediaPlayerController` + `CatalogPlaybackQueueItemProvider`). Library/catalog **data** uses **REST**, mirroring what iOS gets from MusicKit.

---

## Goal: zero `UNSUPPORTED_PLATFORM` for public APIs

Everything below must work on Android (parity with `ios/ExpoAppleMusicModule.swift`).

### Auth — done

| Method | Status |
|--------|--------|
| `authorization` | Done |

### Implement (all of these)

| Method | iOS source | Android implementation |
|--------|------------|------------------------|
| `checkSubscription` | `SubscriptionService` | REST inference — see below |
| `catalogSearch` | `CatalogService.search` | `GET /v1/catalog/{storefront}/search` |
| `getUserPlaylists` | `LibraryService.getPlaylists` | `GET /v1/me/library/playlists` |
| `getLibrarySongs` | `LibraryService.getSongs` | `GET /v1/me/library/songs` |
| `getPlaylistSongs` | `LibraryService.getPlaylistSongs` | `GET /v1/me/library/playlists/{id}/tracks` |
| `getTracksFromLibrary` | `LibraryService.getRecentlyPlayed` | REST recently-played / history endpoint — match iOS payload shape |
| `setPlaybackQueue` | `QueueService.setQueue` | Playback AAR + REST when library IDs need resolution |
| `playLibrarySong` | `QueueService.playLibrarySong` | Same |
| `playLibraryPlaylist` | `QueueService.playLibraryPlaylist` | Same |
| `configurePlayer` | `PlaybackController.configureAudioSession` | Parity return; audio focus optional |
| `getCurrentState` | `PlaybackController` + mapper | Playback AAR listener |
| `play` / `pause` / skip / seek / restart / `togglePlayerState` | `PlaybackController` | Playback AAR |
| Playback events + `OnStartObserving` | `PlaybackObserver` | `MediaPlayerController.Listener` |

**No JS API changes.** Map REST + SDK results to existing types in `src/types/`.

---

## Prerequisites (already done)

- Auth AAR + playback AAR linked (`expo-module.config.json`, `android/build.gradle`)
- AAR files in app-owned directory (copied at prebuild by config plugin; see **[BUILDING_LOCALLY.md](./BUILDING_LOCALLY.md)**)
- Developer JWT in `MusicKitAuthStorage` after `authorize()` / `setDeveloperToken()`; music user token returned to JS (app-owned)
- Manifest `<queries>` for Apple Music app

---

## Shared native layer

```
AppleMusicRestStack.kt          // OkHttp transport + domain *RestClient slices
  ├── getStorefront()
  ├── catalogSearch(term, types, limit, offset)
  ├── getLibraryPlaylists(limit, offset)
  ├── getLibrarySongs(limit, offset)
  ├── getPlaylistTracks(playlistId)
  ├── getRecentlyPlayed()      // match getTracksFromLibrary shape
  └── resolveLibraryItem(...)  // used by AndroidQueueService for playback

AppleMusicJsonMapper.kt         // API resources → Song / Album / Playlist dicts (see docs/TYPES.md)
  └── mirror ios/MusicItemMapper.swift field names

AndroidCatalogService.kt        // catalogSearch (mirror CatalogService.swift)
AndroidLibraryService.kt        // library reads (mirror LibraryService.swift)
AndroidQueueService.kt          // setPlaybackQueue, playLibrary* (mirror QueueService.swift)
AndroidPlaybackController.kt    // MediaPlayerController, native libs, transport
AndroidPlaybackObserver.kt      // events
MusicKitTokenProvider.kt        // TokenProvider → AuthenticatedSession
AuthenticatedSession.kt         // REST/catalog credential snapshot + storefront cache
AndroidSubscriptionService.kt   // checkSubscription approximation
ExpoAppleMusicModule.kt         // wire all methods
```

Add HTTP dependency in `android/build.gradle` (e.g. `okhttp` + coroutines).

---

## `checkSubscription` on Android

There is no `MusicSubscription.current` on Android. Return the same **four booleans** (`CheckSubscription`) using best-effort inference:

| Field | Suggested source |
|-------|------------------|
| `canPlayCatalogContent` | Music user token present + successful lightweight catalog or library request |
| `canBecomeSubscriber` | Default `false` or auth SDK hint if available |
| `hasCloudLibraryEnabled` | Successful `GET /v1/me/library/songs?limit=1` |
| `isMusicCatalogSubscriptionEligible` | Same as `canBecomeSubscriber` (iOS compat) |

Document approximation in code comments. Throw structured errors only when tokens missing.

---

## Library ID rules (playback)

Mirror `QueueService.isLibraryId`:

```kotlin
id.startsWith("l.") || id.startsWith("i.") || id.startsWith("p.")
```

- Library + `station` in `setPlaybackQueue` → error (same as iOS)
- `playLibraryPlaylist(playlistId, startingAt)` — treat `startingAt == -1` as `0`

Return strings match iOS:

- `"Track(s) added to queue"`
- `"Library song added to queue"`
- `"Library playlist added to queue"`

---

## Playback AAR

1. Load natives before SDK: `c++_shared`, `appleMusicSDK`
2. `MediaPlayerControllerFactory.createLocalController(context, handler, MusicKitTokenProvider)`
3. Queue via `CatalogPlaybackQueueItemProvider.Builder` — spike library vs catalog IDs on device
4. If library IDs fail on provider alone, resolve to catalog song IDs via `LibraryRestClient` first

**Catalog and library playback** both need a valid **music user token** for the playback SDK (it calls `GET /v1/me/storefront`). After `authorization` succeeds, native keeps the token in `AuthenticatedSessionCache` for `setPlaybackQueue` / `playLibrary*` (in-memory only; JS still owns long-term storage — same contract as web MusicKit JS session and iOS `MusicKitAuthStorage` for REST). `Player.setQueue` without a prior `Auth.authorize()` rejects with `MISSING_MUSIC_USER_TOKEN`.

`MediaContainerType` in AAR: `ALBUM`, `PLAYLIST` only — confirm catalog `station` during spike.

---

## REST reference (Apple Music API)

Base: `https://api.music.apple.com`

| Feature | Endpoint |
|---------|----------|
| Storefront | `GET /v1/me/storefront` |
| Catalog search | `GET /v1/catalog/{storefront}/search?term=&types=songs,albums` |
| Library playlists | `GET /v1/me/library/playlists` |
| Library songs | `GET /v1/me/library/songs` |
| Playlist tracks | `GET /v1/me/library/playlists/{id}/tracks` |
| Recently played | Confirm against [Apple Music API](https://developer.apple.com/documentation/applemusicapi) — match iOS `recentlyPlayedItems` shape |

Pagination: honor `limit` / `offset` from JS options (defaults like iOS: 25 / 0).

---

## Implementation order

1. **`AppleMusicRestStack` + mapper** — storefront, tokens, one catalog + one library call proven in isolation
2. **Library read APIs** — `getUserPlaylists`, `getLibrarySongs`, `getPlaylistSongs`, `getTracksFromLibrary`
3. **`catalogSearch`**
4. **`checkSubscription`** approximation
5. **Playback spike** — device, catalog song plays
6. **`AndroidPlaybackController` + transport + `getCurrentState`**
7. **`AndroidQueueService`** — catalog + library queue, `playLibrarySong`, `playLibraryPlaylist`
8. **`AndroidPlaybackObserver` + module event wiring**
9. **Example app** — single UI for iOS and Android (remove auth-only Android branch)

---

## Example app

`example/App.tsx` should use the **same** controls on both platforms: authorize (with dev token on Android), search, play/pause, playback hooks. See [docs/CLI.md](./CLI.md) for token setup.

---

## Testing

- Physical **ARM** device (playback AAR has no x86 natives)
- Apple Music installed, user subscribed and signed in
- `yarn dev-token` → `example/.env.local`

---

## Effort (rough)

| Area | Days |
|------|------|
| REST client + mapper + library reads + catalog search | 4–6 |
| checkSubscription + error normalization | 1 |
| Full playback (catalog + library) + events | 5–7 |
| Example + device QA | 2 |

**Total: ~12–16 focused days** for one agent familiar with Android + Apple Music API.

---

## Definition of done

- [ ] No public native method throws `UNSUPPORTED_PLATFORM` on Android
- [ ] All responses match existing TypeScript interfaces
- [ ] REST runs in Kotlin, not in JS
- [ ] Playback + library + catalog paths tested on device
- [ ] Example app feature-parity on Android vs iOS
- [ ] [docs/AUTH.md](./AUTH.md) accurate for token storage

---

## Agent prompt (copy/paste)

```
Implement full Android parity with iOS per docs/ANDROID_IMPLEMENTATION.md.
Native Kotlin must call Apple Music REST API for catalog search and all library
read methods; use the playback AAR for Player/MusicKit queue and transport.
Return the same bridge payloads as iOS. Do not change public TypeScript APIs.
Reuse MusicKitAuthStorage tokens. Test on a physical ARM device.
```

---

## iOS reference files

| Android service | iOS file |
|-----------------|----------|
| `AndroidCatalogService` | `ios/CatalogService.swift` |
| `AndroidLibraryService` | `ios/LibraryService.swift` |
| `AndroidQueueService` | `ios/QueueService.swift` |
| `AndroidPlaybackController` | `ios/PlaybackController.swift` |
| `AndroidPlaybackObserver` | `ios/PlaybackObserver.swift` |
| `AndroidSubscriptionService` | `ios/SubscriptionService.swift` |
| `AppleMusicJsonMapper` | `ios/MusicItemMapper.swift` |
| Module wiring | `ios/ExpoAppleMusicModule.swift` |

Apple SDK sample (playback): `Android-MusicKit-SDK-*/sdk-test-app.zip` → `MediaPlaybackService.java`, `MediaSessionManager.java`.
