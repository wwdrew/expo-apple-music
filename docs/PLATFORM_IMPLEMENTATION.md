# Platform implementation matrix

How each **public JS method** is implemented on iOS vs Android. The TypeScript API is identical; only the native transport differs.

**Policy (iOS):** Use **MusicKit** for auth, catalog (native-first with REST fallback), and **library playback** queue resolution. Use **REST** (`AppleMusicRestClient`) for library/history **reads**, REST-only writes, and catalog gaps. Both paths must emit the **same bridge object shape** as Android’s `AppleMusicJsonMapper` (see [TYPES.md](./TYPES.md), `fixtures/*.json`).

**Policy (Android):** REST via `*RestClient` + `AppleMusicRestStack` + `AppleMusicJsonMapper` for all data reads/writes; MusicKit AAR for auth and playback.

**Mappers on iOS:**

| Mapper | Source |
|--------|--------|
| `MusicItemMapper` | MusicKit types (native) |
| `RestJsonMapper` | `api.music.apple.com` JSON (REST) |

**Bridge contract (fixture tests):** [BRIDGE_CONTRACT.md](./BRIDGE_CONTRACT.md) — golden `fixtures/` + `fixtures/expected/`; TS and Kotlin adapters must stay aligned.

---

## Auth

| JS API | iOS | Android |
|--------|-----|---------|
| `Auth.authorize(developerToken?)` | Native `SKCloudServiceController` + optional dev JWT; returns `musicUserToken` to JS | MusicKit Auth SDK activity |
| `Auth.setDeveloperToken(developerToken)` | Native `setDeveloperToken` — no user UI | Same storage update |
| `Auth.checkSubscription(musicUserToken)` | Native `MusicSubscription` / capability checks | Heuristic (token + library probe) |
| `Auth.getStorefront(musicUserToken)` | REST `GET /v1/me/storefront` | REST |

---

## Catalog

**Architecture:** Catalog ID resolution and native/REST fallback stay in `CatalogService` / `CatalogSearchStoreFactory`. Do not add fetch or resolution branches in `ExpoAppleMusicModule`, the module definition, or `ExpoBridgeCatalog` — those layers only register bridges and map envelopes.

| JS API | iOS | Android |
|--------|-----|---------|
| `Catalog.search()` | **Native** `MusicCatalogSearchRequest` first; **REST** fallback only when native auto-token fails and a developer JWT is stored | REST search |
| `Catalog.getSong` / `getAlbum` / `getArtist` / `getPlaylist` / `getStation` / `getMusicVideo` | **Native** `MusicCatalogResourceRequest` | REST catalog resource |
| `Catalog.getAlbumTracks` | REST relationship | REST |
| `Catalog.getArtistAlbums` | REST relationship | REST |
| `Catalog.getPlaylistTracks` | REST relationship | REST |
| `Catalog.getCharts()` | REST charts | REST |

---

## Library (read)

iOS library **reads** use REST for pagination parity with Android/web (`limit`/`offset`, `/v1/me/library/search`). There is no unused “native list” path — `MusicLibraryRequest` helpers on `LibraryService` (`fetchSong` / `fetchAlbum` / `fetchPlaylist`) exist only for **playback queue** resolution in `QueueService` (`playLibrarySong` / `playLibraryPlaylist` / library-typed `setQueue`).

| JS API | iOS | Android |
|--------|-----|---------|
| `Library.getPlaylists()` | REST | REST |
| `Library.getSongs()` | REST | REST |
| `Library.getPlaylistTracks()` | REST | REST |
| `Library.getArtists()` | REST | REST |
| `Library.getAlbums()` | REST | REST |
| `Library.getMusicVideos()` | REST | REST |
| `Library.search()` | REST `GET /v1/me/library/search` | REST `GET /v1/me/library/search` |
| `Catalog.getByIds()` | REST `GET .../{type}?ids=` | REST |

---

## History

All history methods use **REST** on iOS (`HistoryService` → `AppleMusicRestClient`) and Android — there is no MusicKit history read path.

| JS API | iOS | Android |
|--------|-----|---------|
| `History.getRecentlyPlayedResources()` | REST `GET /v1/me/recent/played` (often capped ~10) | REST `GET /v1/me/recent/played` |
| `History.getRecentlyPlayedTracks()` | REST `GET /v1/me/recent/played/tracks` | REST |
| `History.getHeavyRotation()` | REST `GET /v1/me/history/heavy-rotation` | REST |
| `History.getRecentlyPlayedStations()` | REST `GET /v1/me/recent/radio-stations` | REST |
| `History.getRecentlyAdded()` | REST `GET /v1/me/library/recently-added` | REST |

---

## Recommendations

| JS API | iOS | Android |
|--------|-----|---------|
| `Recommendations.get()` (no ids) | REST `GET /v1/me/recommendations` | REST `GET /v1/me/recommendations` |
| `Recommendations.get({ ids })` | REST | REST |
| `Recommendations.getReplay()` | REST `GET /v1/me/music-summaries` | REST |

Heavy rotation: `History.getHeavyRotation()` — not this module ([RECOMMENDATIONS.md](./RECOMMENDATIONS.md)).

---

## Ratings & library mutations

| JS API | iOS | Android |
|--------|-----|---------|
| `Ratings.*` | REST (requires stored dev + user tokens) | REST |
| `LibraryMutations.*` | REST | REST |

---

## Playback

| JS API | iOS | Android |
|--------|-----|---------|
| `Player.setQueue()` | **Native** MusicKit player + catalog/library queue | MusicKit playback AAR |
| `Player.playLibrarySong` / `playLibraryPlaylist` | **Native** (+ library ID resolution in queue service) | REST resolve catalog IDs + queue |
| `Player.configurePlayer(options?)` | Native `ApplicationMusicPlayer` (default) or `SystemMusicPlayer`; full `AVAudioSession` | Stub payload; audio focus via playback AAR |
| `Player` transport, `getCurrentState`, hooks | **Native** | Native AAR |

**Player backends (iOS):** Default is **`application`** (`ApplicationMusicPlayer`) — the in-app queue used by hooks and the example player bar. Prefer `player: 'system'` (or legacy `playerType`) only when you need Music-app / system playback. Prefer top-level `mixWithOthers` for mixing; use `audioSession` only for advanced category/mode/options. Full guide: [PLAYBACK.md](./PLAYBACK.md).

On **Android**, catalog `setQueue` requires a music user token in the native session (set when `authorization` returns `authorized`, or when `playLibrary*` passes a token). **Web** relies on MusicKit JS authorize; **iOS** uses system MusicKit account state.

---

## Bridge contract (parity rules)

| Field | Rule |
|-------|------|
| `Song.id` | Prefer catalog playback id from `playParameters` when present; else resource / `MusicItemID.rawValue` |
| `Song.duration` | **Milliseconds** (number) |
| `MusicVideo.duration` | **Milliseconds** (number) |
| `Album.trackCount` | Number |
| `Playlist.trackCount` | Number; prefer API `trackCount`, not loaded `tracks.count` when available |
| Library IDs | `i.`, `l.`, `p.` prefixes — see [RESOURCE_IDS.md](./RESOURCE_IDS.md) |

---

## Known behavioral differences (not mapper bugs)

| Area | Note |
|------|------|
| Recent played containers | Apple caps some `/v1/me/recent/*` responses (e.g. ~10 items on resources); iOS and Android both use REST |
| `Auth.checkSubscription()` | Android infers flags; iOS uses MusicKit subscription APIs |
| Catalog station queue | iOS native ✅; Android playback AAR ❌ |
| `Player.configurePlayer` | iOS: real backend + AVAudioSession; Android/web: stub payload only ([PLAYBACK.md](./PLAYBACK.md)) |
| REST on iOS without dev JWT | GET may use `MusicDataRequest` fallback; **writes** require stored tokens |
