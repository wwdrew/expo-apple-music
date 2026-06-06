# Web — full API parity (implementation plan)

Single handoff to implement **every** public `ExpoAppleMusic` bridge method on **web** so the existing TypeScript API (`Auth`, `MusicKit`, `Player`, hooks) works unchanged in Expo web builds.

Read [CONTEXT.md](../CONTEXT.md), [docs/AUTH.md](./AUTH.md), and [docs/ANDROID_IMPLEMENTATION.md](./ANDROID_IMPLEMENTATION.md) — the Android REST table and JSON field names are the **web data contract** as well.

---

## Summary: what web is (and is not)

| | Web |
|---|-----|
| **Same as** | Android’s **Apple Music API** model (developer JWT + music user token, `/v1/catalog/...`, `/v1/me/library/...`) |
| **Different from** | iOS native MusicKit (no OS player, no `SKCloudServiceController`, no developer-token-free auth) |
| **Apple SDK** | [MusicKit on the Web](https://developer.apple.com/documentation/musickitjs) (MusicKit JS v3, hosted script) |
| **Not** | Raw `fetch('https://api.music.apple.com/...')` from app code without MusicKit JS (CORS, token handling, and Apple’s supported path) |

**Crossover with Android:** Endpoint list, pagination, library ID rules (`l.`, `i.`, `p.`), and `AppleMusicJsonMapper.kt` → port to TypeScript. Android’s OkHttp client becomes MusicKit JS `music.api` (or equivalent) plus the same mappers on JSON `data[]` resources.

---

## Architecture

| Layer | iOS | Android | Web (target) |
|-------|-----|---------|--------------|
| JavaScript | `Auth` / `MusicKit` / `Player` / hooks | Unchanged | Unchanged |
| Bridge | `ExpoAppleMusic` native module | Same module name | Same module name (`ExpoAppleMusic`) |
| Implementation | Swift + MusicKit | Kotlin + REST + playback AAR | **TypeScript** + MusicKit JS |
| Apple | OS frameworks | `api.music.apple.com` + AARs | MusicKit JS → Apple Music API + in-browser player |

```
src/modules/*.ts          (no public API changes)
src/native-module.ts      → requireNativeModule (ios/android)
src/native-module.web.ts  → web module (Metro resolves .web.ts)
web/
  ExpoAppleMusicModule.ts       // bridge: all AsyncFunctions + events
  MusicKitLoader.ts             // load v3 script once, configure()
  WebCatalogService.ts          // catalogSearch
  WebLibraryService.ts          // library reads
  WebQueueService.ts            // setPlaybackQueue, playLibrary*
  WebPlaybackController.ts      // play/pause/skip/seek, getCurrentState
  WebPlaybackObserver.ts        // MK player events → bridge events
  WebSubscriptionService.ts     // checkSubscription inference
  apple-music-json-mapper.ts    // port of android/.../AppleMusicJsonMapper.kt
  apple-music-errors.ts         // codes aligned with native
```

**Rule:** Map MusicKit JS / API JSON to the **same plain objects** iOS already returns (`Song`, `Playlist`, `PlaybackState`, etc.). See [TYPES.md](./TYPES.md). Do not change `src/types/*` unless iOS and Android already agree on a fix.

---

## Prerequisites (app + Apple Developer)

1. **MusicKit** enabled on your App ID in the [Apple Developer portal](https://developer.apple.com/account/resources) → **Identifiers** → App IDs → your app → **App Services** → **MusicKit** (same toggle as iOS).
2. **MusicKit private key** — **Keys** → create a key with **Media Services** / MusicKit → download `.p8`; sign developer JWTs with Team ID + Key ID ([CLI.md](./CLI.md)).
3. **Developer token** from your **backend** (or dev-only env var in the example app). Never ship the `.p8` private key in the client.
4. **Web origins (optional):** restrict JWTs with an `origin` claim in the payload (not a portal “domain list”). Omit for dev; add `http://localhost:<port>` when you want origin lock-down — see [AUTH.md](./AUTH.md#web-origin-optional-jwt-claim).
5. **Expo web** in the host app (`expo start --web`); test in browsers Apple supports for MusicKit JS (Safari, Chrome, Firefox — verify playback per target).
6. User must have an **Apple Music subscription** (or trial) and complete the web sign-in flow.

### Config plugin

The existing config plugin only sets `NSAppleMusicUsageDescription` on **iOS**. Web needs **no** native plist changes. Document in README:

- Host app must load MusicKit JS (module can inject script tag on first use).
- Production apps fetch `developerToken` from their API before `Auth.authorize(token)`.

---

## Expo module wiring

1. Add `"web"` to `platforms` in `expo-module.config.json`.
2. Implement `web/ExpoAppleMusicModule.ts` (or `src/ExpoAppleMusicModule.web.ts`) exporting a module object with:
   - `name`: `'ExpoAppleMusic'`
   - Same method names as `ios/ExpoAppleMusicModule.swift` / Android bridge
   - Event names: `onPlaybackStateChange`, `onCurrentSongChange`, `onPlaybackTimeUpdate`, `onPlaybackError`
3. Add `src/native-module.web.ts` that registers the web module instead of `requireNativeModule` (Metro platform extension).
4. Use `LegacyEventEmitter` on web the same way as native so `Player.addListener` and hooks keep working.

**SSR:** Do not call `MusicKit.configure` at import time. Lazy-init on first `authorize()` or first API use; guard `typeof window !== 'undefined'`.

---

## MusicKit JS bootstrap

1. Inject once (idempotent):

   ```html
   <script src="https://js-cdn.music.apple.com/musickit/v3/musickit.js"></script>
   ```

   Or dynamic `document.createElement('script')` from `MusicKitLoader.ts`.

2. After `window.MusicKit` exists:

   ```ts
   await MusicKit.configure({
     developerToken, // from Auth.authorize() argument — same as Android
     app: { name: '...', build: '...' },
   });
   const music = MusicKit.getInstance();
   ```

3. **Authorize:** `await music.authorize()` → map result to `AuthStatus` (see [Auth](#auth-authorization)).

4. Store developer token in **module memory** (and optionally `sessionStorage` for the session only). Music user token is managed by MusicKit JS — do not expose it to app JS unless debugging.

---

## Goal: parity matrix (what can and cannot be done)

Legend: ✅ supported · ⚠️ supported with differences · ❌ not supported · N/A not applicable on web

### Auth

| API | Web | Notes |
|-----|-----|-------|
| `Auth.authorize(developerToken?, options?)` | ✅ | **`developerToken` required** (like Android). `options` (`hideStartScreen`, `startScreenMessage`) are **Android-only** — ignore on web (same as iOS). |
| `Auth.checkSubscription()` | ⚠️ | No `MusicSubscription.current`. Use REST/MK inference (same strategy as [Android](./ANDROID_IMPLEMENTATION.md#checksubscription-on-android)). |

### Catalog & library (reads)

| API | Web | Notes |
|-----|-----|-------|
| `MusicKit.catalogSearch(term, types, options?)` | ✅ | `GET /v1/catalog/{storefront}/search` via MK JS / `music.api`. Types: `songs`, `albums`. Pagination: `limit` / `offset` (default 25 / 0). |
| `getUserPlaylists(options?)` | ✅ | `GET /v1/me/library/playlists` |
| `getLibrarySongs(options?)` | ✅ | `GET /v1/me/library/songs` |
| `getPlaylistSongs(playlistId, options?)` | ✅ | `GET /v1/me/library/playlists/{id}/tracks` |
| `getTracksFromLibrary()` | ⚠️ | `GET /v1/me/recent/played` — API max **10** items (same Android note). Match iOS `recentlyPlayedItems` shape via mapper. |

### Playback & queue

| API | Web | Notes |
|-----|-----|-------|
| `setPlaybackQueue(itemId, type)` — `song` | ✅ | MK `setQueue` with catalog or library song id + `playParams` when library |
| `setPlaybackQueue` — `album` | ✅ | |
| `setPlaybackQueue` — `playlist` | ✅ | Catalog and library playlists |
| `setPlaybackQueue` — `station` (catalog) | ⚠️ | **Spike required.** iOS supports catalog stations; Android AAR does not. MK JS documents `station` queue type — verify in browser; may work on web where Android fails. |
| `setPlaybackQueue` — `station` (library) | ❌ | Same as iOS/Android — not a library item type |
| `setPlaybackQueue` — library id + `station` type | ❌ | Reject with same error semantics as iOS (`unsupportedLibraryType`) |
| `playLibrarySong(songId)` | ✅ | Queue library song (`i.*`) — use `playParams` from library resource when required |
| `playLibraryPlaylist(playlistId, startingAt?)` | ✅ | `startingAt === -1` → `0` |
| `Player.play` / `pause` / skip / seek / restart / `togglePlayerState` | ✅ | MK player controls |
| `Player.getCurrentState()` | ⚠️ | Map MK `nowPlayingItem` / playback state to `PlaybackState`; field timing may differ slightly from native |
| `Player.configurePlayer(mixWithOthers)` | ⚠️ | Return `{ mixWithOthers }` for API shape; **no** AVAudioSession equivalent on web |
| Hooks: `usePlaybackState`, `useIsPlaying`, `useCurrentSong` | ✅ | Driven by same events if observer maps correctly |

### Events

| Event | Web | Notes |
|-------|-----|-------|
| `onPlaybackStateChange` | ✅ | Poll or subscribe to MK `playbackStateDidChange` / `mediaItemDidChange` |
| `onCurrentSongChange` | ✅ | |
| `onPlaybackTimeUpdate` | ⚠️ | May need `requestAnimationFrame` or MK time update events; rate may differ from iOS |
| `onPlaybackError` | ⚠️ | Map MK errors to `{ message, code, domain, operation }` — codes **will not** match `NSError` exactly |

### Platform / product limitations (cannot fix in this module)

| Limitation | Why |
|------------|-----|
| **No offline playback** | Streaming-only in browser |
| **No background audio parity** | Browser tab / OS policies; not a full media session like native |
| **Autoplay restrictions** | First `play()` may require user gesture; document for app developers |
| **Browser playback variance** | Some tracks/storefronts behave differently in Chrome vs Safari (Apple/community reports) — test real catalog IDs |
| **No “is Apple Music installed?”** | N/A on web; user signs in via web auth UI |
| **Developer token in client** | JWT must be short-lived and minted server-side in production |
| **Private key in Expo app** | ❌ Never — use backend or `yarn dev-token` for example only |
| **Exact iOS permission dialog** | Web uses MusicKit authorize UI, not `NSAppleMusicUsageDescription` |
| **Android upsell screen options** | `hideStartScreen` / `startScreenMessage` not applicable |

---

## Bridge method checklist

Implement every method exposed by `ios/ExpoAppleMusicModule.swift` (same names Android uses):

| Method | Web implementation |
|--------|-------------------|
| `authorization` | `MusicKit.configure` + `music.authorize()` → `AuthStatus` |
| `checkSubscription` | `WebSubscriptionService` — inference (see below) |
| `catalogSearch` | `WebCatalogService` — REST via MK JS, `apple-music-json-mapper` |
| `getUserPlaylists` | `WebLibraryService` |
| `getLibrarySongs` | `WebLibraryService` |
| `getPlaylistSongs` | `WebLibraryService` |
| `getTracksFromLibrary` | `WebLibraryService` — recently played endpoint |
| `setPlaybackQueue` | `WebQueueService` |
| `playLibrarySong` | `WebQueueService` |
| `playLibraryPlaylist` | `WebQueueService` |
| `configurePlayer` | No-op audio session; return `{ mixWithOthers }` |
| `getCurrentState` | `WebPlaybackController` |
| `play` / `pause` / `skipToNextEntry` / `skipToPreviousEntry` / `restartCurrentEntry` / `seekToTime` / `togglePlayerState` | `WebPlaybackController` |
| `OnStartObserving` / `OnStopObserving` | Start/stop `WebPlaybackObserver` |

Return strings (match iOS):

- `"Track(s) added to queue"`
- `"Library song added to queue"`
- `"Library playlist added to queue"`

---

## Auth (`authorization`)

Web aligns with **Android**, not iOS:

| Argument | Web |
|----------|-----|
| `developerToken` | **Required** — reject with `MISSING_DEVELOPER_TOKEN` if missing/blank |
| `options` | Ignored (`hideStartScreen`, `startScreenMessage` are Android-only) |

### `AuthStatus` mapping

Normalize MusicKit JS authorize results to the same union as iOS/Android:

| Outcome | `AuthStatus` |
|---------|--------------|
| Success / authorized | `authorized` |
| User closed popup / denied | `denied` |
| No subscription / ineligible | `restricted` |
| Not yet requested (rare on web) | `notDetermined` |
| Invalid developer token / SDK error | `unknown` |

No separate `cancelled` — user dismissal → `denied` (same rule as [AUTH.md](./AUTH.md)).

---

## `checkSubscription` on web

There is no `MusicSubscription.current` in the browser. Return `CheckSubscription` using the same **best-effort inference** as Android:

| Field | Suggested source |
|-------|------------------|
| `canPlayCatalogContent` | Authorized + lightweight catalog or library request succeeds |
| `canBecomeSubscriber` | Default `false` or MK hint if exposed |
| `hasCloudLibraryEnabled` | `GET /v1/me/library/songs?limit=1` succeeds |
| `isMusicCatalogSubscriptionEligible` | Same as `canBecomeSubscriber` |

Throw structured errors when not authorized (missing tokens), not `UNSUPPORTED_PLATFORM`.

---

## JSON mapper (`apple-music-json-mapper.ts`)

Port `android/.../AppleMusicJsonMapper.kt` to TypeScript. Target field names must match `ios/MusicItemMapper.swift`:

| Resource | Fields |
|----------|--------|
| Song | `id`, `title`, `artistName`, `artworkUrl`, `duration` (string) |
| Album | `id`, `title`, `artistName`, `artworkUrl`, `trackCount` (string) |
| Playlist | `id`, `name`, `description`, `artworkUrl`, `trackCount` |
| Recently played | `id`, `type`, `title`, `subtitle`, `artworkUrl` (per iOS mapper) |

Artwork URL: replicate Kotlin logic (`url` template + `width`/`height` substitution).

---

## Library ID rules (playback)

Same as [ANDROID_IMPLEMENTATION.md](./ANDROID_IMPLEMENTATION.md#library-id-rules-playback):

```ts
id.startsWith('l.') || id.startsWith('i.') || id.startsWith('p.')
```

- Library IDs need **`playParams`** from the library resource when MK JS requires them for playback (fetch song/playlist metadata before `setQueue` if queue fails with id alone).
- `playLibraryPlaylist(playlistId, startingAt)` — `startingAt === -1` → `0`.

---

## REST reference (shared with Android)

Base: `https://api.music.apple.com` (called **through MusicKit JS**, not direct app `fetch`).

| Feature | Endpoint |
|---------|----------|
| Storefront | `GET /v1/me/storefront` |
| Catalog search | `GET /v1/catalog/{storefront}/search?term=&types=songs,albums` |
| Library playlists | `GET /v1/me/library/playlists` |
| Library songs | `GET /v1/me/library/songs` |
| Playlist tracks | `GET /v1/me/library/playlists/{id}/tracks` |
| Recently played | `GET /v1/me/recent/played` |

Cache storefront id in module state after first resolve.

---

## Implementation order

1. **Scaffold** — `expo-module.config.json`, `native-module.web.ts`, `MusicKitLoader`, empty module that loads script
2. **`authorization`** + token validation + `MISSING_DEVELOPER_TOKEN`
3. **`apple-music-json-mapper.ts`** — unit-test against fixture JSON from Android/iOS responses
4. **Library reads** — `getUserPlaylists`, `getLibrarySongs`, `getPlaylistSongs`, `getTracksFromLibrary`
5. **`catalogSearch`**
6. **`checkSubscription`** inference
7. **Playback spike** — catalog song `setPlaybackQueue` + `play` in Chrome and Safari
8. **`WebPlaybackController`** + `getCurrentState` + transport methods
9. **`WebQueueService`** — album/playlist/library; station spike
10. **`WebPlaybackObserver`** + hook QA in example app
11. **README platform table** + [docs/AUTH.md](./AUTH.md) web section

---

## Example app

Update `example/App.tsx` for three platforms:

- iOS: `Auth.authorize()` (no token)
- Android: `Auth.authorize(EXPO_PUBLIC_APPLE_MUSIC_DEVELOPER_TOKEN)`
- Web: same env token as Android; run `cd example && yarn web`

Use [docs/CLI.md](./CLI.md) for `example/.env.local`.

---

## Testing

| Check | Environment |
|-------|-------------|
| Auth + library reads | Desktop browser, subscribed Apple ID |
| Playback | Safari + Chrome (minimum); Firefox if you claim support |
| Hooks / events | Leave player running 30s+; seek, skip |
| Token errors | Expired JWT → `unknown` or structured reject |
| SSR / import | Ensure no crash when `window` undefined (Expo web SSR if enabled) |

---

## Effort (rough)

| Area | Days |
|------|------|
| Scaffold + MK loader + auth | 1–2 |
| Mapper + library reads + catalog search | 2–3 |
| checkSubscription + errors | 0.5–1 |
| Playback + queue + library play | 3–4 |
| Events + hooks + example + cross-browser QA | 2–3 |

**Total: ~9–13 focused days** for one developer familiar with MusicKit JS and Expo web modules (less if Android mapper/REST work is already fresh).

---

## Definition of done

- [x] `"web"` in `expo-module.config.json`; Metro resolves web native module (`src/native-module.web.ts`, `src/bridge/*`)
- [x] No public bridge method throws `UNSUPPORTED_PLATFORM` on web (except documented ❌ cases: library `station`, etc.)
- [x] All responses match existing TypeScript interfaces in `src/types/` — fixture tests (`bridge-contract.test.ts`); browser spot-check in [QA_SIGNOFF.md](./QA_SIGNOFF.md)
- [x] Data calls go through MusicKit JS (not raw unauthenticated `fetch` to Apple API) — `WebAppleMusicRestTransport`
- [x] Mapper parity vs iOS/Android field names — shared `fixtures/` + `yarn test`; browser spot-check in [QA_SIGNOFF.md](./QA_SIGNOFF.md)
- [ ] Playback + hooks work in Safari and Chrome with subscribed account (30s+ session) — [QA_SIGNOFF.md](./QA_SIGNOFF.md)
- [ ] Example app runs `expo start --web` with shared UI — [QA_SIGNOFF.md](./QA_SIGNOFF.md)
- [x] README platform parity table includes web column
- [x] [docs/AUTH.md](./AUTH.md) documents web auth (developer token required, no Android upsell options)

---

## Agent prompt (copy/paste)

```
Implement full web parity per docs/WEB_IMPLEMENTATION.md.
Use MusicKit JS v3 for auth, Apple Music API access, and in-browser playback.
Port android/AppleMusicJsonMapper.kt to web/apple-music-json-mapper.ts so bridge
payloads match iOS. Reuse endpoint list from docs/ANDROID_IMPLEMENTATION.md.
Do not change public TypeScript APIs. Add native-module.web.ts and web platform
to expo-module.config.json. Require developerToken on authorize() like Android.
Test in Safari and Chrome with example/.env.local developer JWT.
```

---

## Reference files

| Web service | Primary reference |
|-------------|-----------------|
| `WebCatalogService` | `ios/CatalogService.swift`, `android/.../AndroidCatalogService.kt` |
| `WebLibraryService` | `ios/LibraryService.swift`, `android/.../AndroidLibraryService.kt` |
| `WebQueueService` | `ios/QueueService.swift`, `android/.../AndroidQueueService.kt` |
| `WebPlaybackController` | `ios/PlaybackController.swift`, `android/.../AndroidPlaybackController.kt` |
| `WebPlaybackObserver` | `ios/PlaybackObserver.swift`, `android/.../AndroidPlaybackObserver.kt` |
| `WebSubscriptionService` | `ios/SubscriptionService.swift`, `android/.../AndroidSubscriptionService.kt` |
| `apple-music-json-mapper.ts` | `android/.../AppleMusicJsonMapper.kt`, `ios/MusicItemMapper.swift` |
| REST endpoints | [ANDROID_IMPLEMENTATION.md](./ANDROID_IMPLEMENTATION.md#rest-reference-apple-music-api) |
| Apple | [MusicKit on the Web](https://developer.apple.com/documentation/musickitjs) |
