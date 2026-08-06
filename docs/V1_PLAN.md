# v1.0 plan — full Apple Music API coverage

Plan for completing `@wwdrew/expo-apple-music` before a **1.0.0** release. The package is a **standalone cross-platform Apple Music client** (catalog, library, history, personalization, playback). It was [inspired by](../ATTRIBUTION.md) `@lomray/react-native-apple-music` but does **not** preserve that API or any compatibility layer.

**Status:** Living document — update the [coverage matrix](#coverage-matrix) as endpoints land.

**Related:** [CONTEXT.md](../CONTEXT.md) (terminology), [ANDROID_IMPLEMENTATION.md](./ANDROID_IMPLEMENTATION.md), [WEB_IMPLEMENTATION.md](./WEB_IMPLEMENTATION.md), [AUTH.md](./AUTH.md).

---

## 1. Vision

| Pillar | v1 target |
|--------|-----------|
| **Scope** | **Entire [Apple Music API](https://developer.apple.com/documentation/AppleMusicAPI)** read/write surface that makes sense on mobile + web, plus native playback |
| **Platforms** | iOS, Android, Web (Expo) |
| **Data path** | **One REST contract** for user/catalog HTTP where needed; **iOS prefers MusicKit** for Auth, Catalog search/get, and Playback; Android/web use REST for data + native/MKJS for Auth/Playback |
| **Errors** | Always `AppleMusicError` rejections — never silent empty data |
| **Public API** | **Domain modules** (`Auth`, `Catalog`, `Library`, `History`, `Player`, …) named for Apple’s API domains |

**North star:** A developer can build an Apple Music app without reading Apple’s REST docs for every call — types, pagination, and platform notes live in this package.

**Not a goal:** API compatibility with `@lomray/react-native-apple-music`, `MPMediaLibrary`, or any other wrapper. See [ATTRIBUTION.md](../ATTRIBUTION.md).

---

## 2. What exists today (baseline)

**Updated:** 2026-08-06. Package is past **1.0** (see `package.json`); use [APPLE_MUSIC_API.md](./APPLE_MUSIC_API.md) + [PLATFORM_IMPLEMENTATION.md](./PLATFORM_IMPLEMENTATION.md) as live matrices. Manual QA: [QA_SIGNOFF.md](./QA_SIGNOFF.md); publish: [RELEASE_CHECKLIST.md](./RELEASE_CHECKLIST.md).

### Implemented (~majority of v1 matrix; optional rows still ⬜)

| Domain | Public API | iOS | Android | Web |
|--------|------------|-----|---------|-----|
| Auth | `Auth.authorize`, `checkSubscription`, `getStorefront` | ✅ native sub | ✅ / ⚠️ inferred sub | ✅ / ⚠️ inferred sub |
| Catalog | `Catalog.search`, `get*`, relationships, `getCharts` | ✅ native search/get; REST relationships/charts | ✅ | ✅ |
| Library | `Library.getSongs`, `getPlaylists`, … | ✅ REST reads; native for playback resolve | ✅ | ✅ |
| History | `History.getRecentlyPlayed*`, `getHeavyRotation`, `getRecentlyAdded` | ✅ REST | ✅ (recent cap ~10) | ✅ |
| Ratings / mutations | `Ratings.*`, `LibraryMutations.*` | ✅ REST | ✅ | ✅ |
| Recommendations | `Recommendations.get`, `getReplay` | ✅ REST | ✅ | ✅ |
| Playback | `Player.setQueue`, `playLibrary*`, transport, hooks | ✅ | ✅ / station ❌ | ⚠️ soak QA |
| Public exports | Domain modules only (`src/index.ts`) | ✅ | ✅ | ✅ |

### Remaining debt (post-1.0)

1. **MusicItemMapper** fixture parity (native MusicKit → bridge) alongside REST fixtures.
2. **Web playback** Safari + Chrome soak QA.
3. **Silent-failure / inferred subscription** honesty on Android/web.
4. Keep **docs** aligned with [PLATFORM_IMPLEMENTATION.md](./PLATFORM_IMPLEMENTATION.md) (native-first Catalog/Auth/Playback on iOS).

---

## 3. Target architecture

```
┌─────────────────────────────────────────────────────────────┐
│  TypeScript public API (domain modules only)                 │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│  expo-module bridge (thin AsyncFunctions per domain batch)   │
└─────────────┬───────────────────────────────┬─────────────────┘
              │                               │
   ┌──────────▼──────────┐         ┌──────────▼──────────┐
   │  iOS                 │         │  Android + Web       │
   │  Playback: MusicKit  │         │  Playback: AAR / MKJS│
   │  HTTP: REST client*  │         │  HTTP: REST client   │
   │  Auth: SKCloud + MK  │         │  Auth: Auth SDK / MKJS│
   └─────────────────────┘         └─────────────────────┘
              │                               │
              └───────────┬───────────────────┘
                          ▼
              https://api.music.apple.com/v1/...
              * iOS may keep native catalog search + playback queue
                where REST adds no value; all /me/* and /recent/*
                go through REST for parity.
```

### Layers

| Layer | Responsibility |
|-------|----------------|
| **`src/api/`** | Typed JS methods per Apple API domain; pagination helpers; re-exports |
| **`src/types/`** | Resource types aligned with Apple JSON (`Song`, `Album`, `Artist`, …) — no `I`/`T` prefixes ([TYPES.md](./TYPES.md)) |
| **`src/mappers/`** | TS reference mapper (port of `AppleMusicJsonMapper.kt` / `MusicItemMapper.swift`) |
| **Native `ApiClient`** | Generic `request(method, path, query, body)` + domain thin wrappers |
| **Native playback** | Unchanged split: iOS `PlaybackController`, Android `MediaPlayerController`, Web MK JS |
| **`docs/APPLE_MUSIC_API.md`** | Endpoint ↔ method ↔ platform matrix (updated per PR) |

### iOS strategy (decision)

**Use MusicKit natively when it can do the job.** Use REST only to **fill gaps** (no MusicKit API, or write endpoints). Every path must return the **same bridge shapes** as Android (`AppleMusicJsonMapper` / `fixtures`).

**Native MusicKit (preferred on iOS when it can do the job):**

- `Auth` / subscription (where better than inference)
- **Playback** (queue, transport, now playing, events)
- **Catalog** search and get-by-id
- Library **playback** queue resolution (`MusicLibraryRequest` helpers)

**REST on iOS (gap-fill / pagination parity — see [PLATFORM_IMPLEMENTATION.md](./PLATFORM_IMPLEMENTATION.md)):**

- **Library** list/search reads (`limit`/`offset` parity with Android/web)
- **History** (all methods)
- **Recommendations** + Replay
- Ratings, favorites, library mutations (writes)
- Catalog: relationships (album tracks, …), charts, `getByIds`
- `Auth.getStorefront()` and any call with no MusicKit equivalent

**Requirement:** App passes **music user token** per user-scoped call; **developer JWT** stored natively when provided to `authorize()` / `setDeveloperToken()`. See [PLATFORM_IMPLEMENTATION.md](./PLATFORM_IMPLEMENTATION.md) for the per-method matrix.

**Rationale:** Avoid reimplementing 80+ Swift request types while keeping one TS contract; maintain `MusicItemMapper` and `RestJsonMapper` in lockstep with Kotlin/TS mappers.

---

## 4. Public API shape (v1)

### Domain modules (v1 public API)

```ts
import {
  Auth,
  Catalog,
  Library,
  History,
  Recommendations,
  Ratings,
  Player,
  // hooks
} from '@wwdrew/expo-apple-music';
```

The interim `MusicKit` default export and flat helpers (`catalogSearch`, `getLibrarySongs`, …) are **removed before 1.0.0**, not aliased.

| Module | Apple API area | Example |
|--------|----------------|---------|
| `Auth` | Tokens, subscription | `authorize()`, `setDeveloperToken()`, `checkSubscription(musicUserToken)`, `getStorefront(musicUserToken)` |
| `Catalog` | `/v1/catalog/{storefront}/...` | `search()`, `getSong()`, `getAlbum()`, `getArtist()`, charts |
| `Library` | `/v1/me/library/...` | `getSongs()`, `getArtists()`, `getAlbums()`, `getPlaylists()`, `getPlaylistTracks()` |
| `History` | `/v1/me/recent/...` | `getRecentlyPlayedTracks()`, `getRecentlyPlayedResources()`, `getHeavyRotation()`, `getRecentlyAdded()` |
| `Recommendations` | recommendations + replay | `getRecommendations()`, `getReplayData(year)` |
| `Ratings` | ratings + favorites | `getRating()`, `setRating()`, `addToFavorites()`, … |
| `LibraryMutations` | playlist CRUD, add to library | `createPlaylist()`, `addTracksToPlaylist()`, … |
| `Player` | Native playback | existing transport + queue |

### API rename map (pre-1.0 cleanup)

| Interim (remove) | v1 |
|------------------|-----|
| `MusicKit.catalogSearch` | `Catalog.search` |
| `MusicKit.getLibrarySongs` | `Library.getSongs` |
| `MusicKit.getUserPlaylists` | `Library.getPlaylists` |
| `MusicKit.getPlaylistSongs` | `Library.getPlaylistTracks` |
| `MusicKit.getTracksFromLibrary` | `History.getRecentlyPlayedResources` |
| `MusicKit.setPlaybackQueue` | `Player.setQueue` (or `Catalog.play` — pick one name in Phase 6) |
| `MusicKit.playLibrarySong` / `playLibraryPlaylist` | `Player.playLibrarySong` / `playLibraryPlaylist` |

### Shared types

```ts
interface PaginatedRequest {
  limit?: number;   // default 25
  offset?: number;  // default 0
}

interface PaginatedResponse<T> {
  data: T[];
  meta?: { total?: number }; // when Apple provides
}
```

Resource types should include **library vs catalog ID** rules (`i.`, `l.`, `p.` prefixes) documented in one place.

---

## 5. Coverage matrix

Legend: **✅** v1 required · **⚠️** v1 if low effort / needed for parity · **🔜** post-v1 · **➖** N/A on mobile (document why)

### 5.1 Essentials

| Endpoint / capability | JS method (proposed) | v1 |
|-----------------------|----------------------|-----|
| Developer + user tokens | `Auth.*` | ✅ (iOS user token for REST) |
| `GET /v1/me/storefront` | `Auth.getStorefront()` | ✅ |

### 5.2 Catalog (`/v1/catalog/{storefront}/...`)

| Area | Operations | v1 |
|------|------------|-----|
| Search | songs, albums, artists, playlists, stations, music-videos | ✅ (expand types beyond songs/albums) |
| Get by ID | song, album, artist, playlist, music-video, station | ✅ |
| Relationships | e.g. album → tracks, artist → albums | ✅ (common set) |
| Charts | albums, songs, music-videos | ⚠️ |
| Multiple resources by ID | batch GET | ⚠️ |
| Curators, activities, record labels | read | 🔜 |

### 5.3 Library (`/v1/me/library/...`)

| Resource | List | Get | Relationships | v1 |
|----------|------|-----|---------------|-----|
| Songs | ✅ exists | add | albums, artists | ✅ |
| Albums | add | add | artists, tracks | ✅ |
| Artists | add | add | albums, … | ✅ |
| Playlists | ✅ exists | add | tracks, … | ✅ |
| Music videos | add | add | — | ⚠️ |
| Search library | add | — | — | ⚠️ |

### 5.4 History (`/v1/me/recent/...`)

| Endpoint | JS method | v1 |
|----------|-----------|-----|
| `GET /v1/me/recent/played` | `History.getRecentlyPlayedResources()` | ✅ (rename from `getTracksFromLibrary`) |
| `GET /v1/me/recent/played/tracks` | `History.getRecentlyPlayedTracks()` | ✅ |
| `GET /v1/me/recent/radio-stations` | `History.getRecentlyPlayedStations()` | ✅ |
| Heavy rotation | `History.getHeavyRotation()` | ✅ |
| Recently added to library | `History.getRecentlyAdded()` | ⚠️ |

Document: **no play timestamps**, **API caps** (e.g. 10 on some calls), not a full play log.

### 5.5 Ratings & favorites

| Operation | v1 |
|-----------|-----|
| Get/set ratings (song, album, playlist, …) | ⚠️ |
| Add/remove favorites | ⚠️ |

### 5.6 Library mutations

| Operation | v1 |
|-----------|-----|
| Create playlist | ⚠️ |
| Add playlist tracks | ⚠️ |
| Add to library (catalog → library) | ⚠️ |

### 5.7 Recommendations & Replay

| Operation | v1 |
|-----------|-----|
| Get recommendations | ⚠️ |
| Get Replay data | 🔜 (niche; document eligibility) |

### 5.8 Playback (native, not REST)

| Capability | v1 |
|------------|-----|
| Queue song / album / playlist (catalog + library) | ✅ |
| Queue station (catalog) | ⚠️ iOS ✅, Android/Web spike |
| Transport + state + hooks + errors | ✅ |
| `configurePlayer` | ✅ (best-effort on Android/Web) |

### 5.9 Web

| Item | v1 |
|------|-----|
| MusicKit JS loader + `Auth` + REST reads | ✅ |
| Playback via MK JS | ✅ |
| Feature parity table in README | ✅ |

---

## 6. Implementation phases

Phases are ordered for **vertical slices** (testable on device) and **dependency order** (tokens → HTTP client → domains → playback polish).

### Phase 0 — Foundation (blocking)

**Goal:** One HTTP pipeline and coverage tracking.

| Task | Deliverable |
|------|-------------|
| Add `docs/APPLE_MUSIC_API.md` | Living matrix (copy section 5; check off per PR) |
| Generic REST client (Android/Kotlin) | `request(GET/POST/DELETE, path, query, body)` |
| Port generic client to iOS (Swift) | Same paths, shared error codes |
| iOS music user token | Persist after authorize; wire into REST headers |
| TS: `PaginatedResponse`, `AppleMusicError` codes | Document all error codes |
| TS: domain module scaffolding | `Catalog`, `Library`, `History`, … empty stubs |
| Fixture tests | JSON fixtures from real API responses; mapper unit tests (TS + Kotlin) |

**Exit:** `Auth.getStorefront()` works on iOS + Android from shared client.

### Phase 1 — History + library completeness

**Goal:** Replace `MPMediaQuery` / listening use cases.

| Task | Deliverable |
|------|-------------|
| `History.getRecentlyPlayedTracks` | REST + iOS client; returns `Song[]` |
| `History.getRecentlyPlayedResources` | Rename/refactor `getTracksFromLibrary` |
| `History.getHeavyRotation`, `getRecentlyPlayedStations` | |
| `Library.getArtists`, `getAlbums` | |
| Expand `Library.getSongs` / playlists if gaps | pagination meta |
| Example app: “Library & History” screen | buttons + list UI |
| Update CONTEXT.md terminology | Library ≠ History |

**Exit:** App can list library artists and recently played tracks on iOS + Android.

### Phase 2 — Catalog depth

**Goal:** Browse and detail screens without raw REST.

| Task | Deliverable |
|------|-------------|
| `Catalog.search` — all search types | artists, playlists, stations, music-videos |
| `Catalog.getSong/Album/Artist/Playlist/...` | by catalog ID |
| Relationship helpers | `getAlbumTracks`, `getArtistAlbums`, … |
| Charts (optional) | `Catalog.getCharts` |
| Remove `MusicKit` export; ship `Catalog.search` only | |

**Exit:** Catalog browse parity with Apple Music API docs for core resources.

### Phase 3 — Mutations (ratings, playlists, library adds) ✅

**Goal:** Write paths Apple documents for user libraries.

| Task | Deliverable |
|------|-------------|
| Ratings GET/SET | `Ratings.getRating`, `setRating`, `clearRating` (catalog + library resource types) |
| Favorites add/remove | `Ratings.addToFavorites`, `removeFromFavorites` |
| Create playlist + add tracks | `LibraryMutations.createPlaylist`, `addTracksToPlaylist` |
| Add catalog resource to library | `LibraryMutations.addToLibrary` |
| Error handling for 403 / subscription | REST clients map HTTP 403 → `permissionDenied` |

**Exit:** Example app mutation buttons; see [APPLE_MUSIC_API.md](./APPLE_MUSIC_API.md) ratings/mutations rows.

### Phase 4 — Recommendations & personalization ✅

| Task | Deliverable |
|------|-------------|
| `Recommendations.get` | `Recommendations.get({ ids? })` — MusicKit on iOS, REST on Android |
| Replay data (if feasible) | `Recommendations.getReplay({ year? })` via `GET /v1/me/music-summaries` |
| Heavy rotation already in History | [RECOMMENDATIONS.md](./RECOMMENDATIONS.md) → [HISTORY.md](./HISTORY.md) |

**Exit:** Example “Recommendations” button; matrix rows updated.

### Phase 5 — Web platform

Follow [WEB_IMPLEMENTATION.md](./WEB_IMPLEMENTATION.md) with REST client shared via MusicKit JS.

| Task | Deliverable |
|------|-------------|
| `native-module.web.ts` + loader | |
| Domain modules call through MK JS `music.api` | same TS types |
| Playback + hooks | |
| README parity row for Web | |

**Exit:** Example app runs in Expo web with auth + history + one catalog call.

### Phase 6 — v1 hardening

| Task | Deliverable |
|------|-------------|
| Playback gaps | catalog stations on Android/Web or document ❌ |
| `checkSubscription` parity | iOS native + Android/Web inference documented |
| Error normalization audit | every native path → `AppleMusicError` |
| Performance | storefront cache, reasonable defaults (`limit`) |
| README + ATTRIBUTION.md aligned with domain API | no third-party migration doc |
| Remove or gate `plugin/tsconfig.tsbuildinfo` from repo | housekeeping |

---

## 7. Testing strategy

| Level | What |
|-------|------|
| **Mapper unit tests** | Kotlin + TS (+ Swift when feasible) against checked-in JSON fixtures |
| **Contract tests** | Optional nightly job with real tokens (CI secret); not required for every PR |
| **Example app** | One screen per domain; manual QA checklist in PR template |
| **Device matrix** | iOS 16.4+ physical; Android ARM physical + Apple Music installed; Web Chrome + Safari |
| **Regression** | Example app + mapper fixtures per domain |

---

## 8. Documentation deliverables (v1)

| Doc | Purpose |
|-----|---------|
| `docs/APPLE_MUSIC_API.md` | Coverage matrix (source of truth) |
| `docs/V1_PLAN.md` | This plan |
| `CONTEXT.md` | Terminology: Catalog / Library / History / Playback |
| `README.md` | Platform parity table — full grid |
| [ATTRIBUTION.md](../ATTRIBUTION.md) | Inspiration + license; explicitly no compatibility |
| `docs/HISTORY.md` | Limits (no timestamps, caps), vs `MPMediaLibrary` |
| `docs/AUTH.md` | iOS user token + developer token on all platforms |

---

## 9. v1.0 release criteria

All required before tagging **1.0.0**:

- [ ] Coverage matrix: every **✅** row implemented on **iOS + Android**
- [ ] Web: Auth + Catalog search + Library reads + History + basic playback
- [ ] Domain public API stable (`Catalog`, `Library`, `History`, …); no `MusicKit` facade
- [ ] No silent failures (empty data on error)
- [ ] Example app demonstrates Auth, Catalog, Library, History, Player
- [ ] `APPLE_MUSIC_API.md` reflects reality (no aspirational ✅)
- [ ] [ATTRIBUTION.md](../ATTRIBUTION.md) and README state standalone scope (no compatibility claims)

**Semantic versioning after v1:**

- **1.x** — additive endpoints and types only (no removal of public exports without major bump)
- **2.0** — reserved for intentional breaking API changes, not “cleanup” of withheld compat layers

---

## 10. Non-goals (v1)

| Item | Reason |
|------|--------|
| **Apple Music Feed** bulk catalog | Different product ([Apple Music Feed](https://developer.apple.com/documentation/AppleMusicFeed)); not client SDK territory |
| **Offline downloads** | Not exposed by API for third-party apps |
| **Full play-by-play analytics** | Apple does not expose complete listening logs |
| **Replacing Apple Music app UI** | Playback/auth constraints on Android |
| **MPMediaLibrary / local files** | Out of scope — use MediaPlayer separately if needed |

---

## 11. Risks & mitigations

| Risk | Mitigation |
|------|------------|
| iOS music user token access for REST | Spike early in Phase 0; block Phase 1 on success |
| Apple API behavior differs by storefront | Cache storefront; document in tests |
| Android station playback unsupported | Parity table ❌; don’t block v1 on stations |
| Scope creep | Coverage matrix + phase gates; 🔜 explicitly deferred |
| Maintainer burden of 80+ endpoints | Generic client + codegen-from-matrix (future); hand-write v1 high-value paths first |

---

## 12. Rough effort order-of-magnitude

Indicative for planning (not commitments):

| Phase | Relative size |
|-------|----------------|
| 0 Foundation | M |
| 1 History + library | M |
| 2 Catalog depth | L |
| 3 Mutations | M |
| 4 Recommendations | S |
| 5 Web | L |
| 6 Hardening | M |

**Critical path:** Phase 0 → 1 → 2 → 6, with Web (5) parallelizable after 0–1.

---

## 13. Immediate next steps

1. **Approve** REST-on-iOS for `/me/*` and history (section 3).
2. **Create** `docs/APPLE_MUSIC_API.md` from section 5 matrix (checkboxes empty).
3. **Phase 0 PR:** generic `AppleMusicApiClient` + iOS user token + `Auth.getStorefront()`.
4. **Phase 1 PR:** `History.getRecentlyPlayedTracks` + `Library.getArtists` + example screen.

---

## Changelog

| Date | Change |
|------|--------|
| 2026-05-19 | Initial v1 plan |
| 2026-05-19 | Drop Lomray compatibility; standalone API per ATTRIBUTION.md |
