# Project context — @wwdrew/expo-apple-music

Reference for humans and agents. Use this file to avoid mixing up **catalog** vs **library** and to align Android work with agreed priorities.

## Commits

This repo uses [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): description` (e.g. `fix(android): …`, `feat(ios): …`, `docs: …`). Use an optional scope when the change is platform- or area-specific.

## TypeScript naming

Do **not** prefix types with `I` or `T`. Use plain names (`Song`, `Album`, `PaginationOptions`). See **[docs/TYPES.md](./docs/TYPES.md)**.

## Terminology

| Term               | Meaning                                                                                            | **Not** this                                                                    |
| ------------------ | -------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **Catalog**        | Apple Music’s global store — all artists, albums, songs available on the service                   | The signed-in user’s personal collection                                        |
| **Library**        | The authenticated user’s Apple Music account data — their songs, playlists, recently played, etc.  | Public/store search                                                             |
| **Catalog search** | `Catalog.search()` — search the **store** (e.g. `"Beatles"` → songs/albums in Apple Music) | Searching “my playlists” or “my library” for an artist                          |
| **Library APIs**   | `Library.getPlaylists`, `getSongs`, `getPlaylistTracks`                                            | Catalog search                                                                  |
| **History APIs**   | `History.getRecentlyPlayedResources`, `getRecentlyPlayedTracks`, …                                 | Library collection reads                                                        |
| **Auth**           | Sign the user into Apple Music and obtain permission/tokens to access **their** data               | Catalog browse without a user (developer token alone is not “auth” for library) |
| **Developer JWT**  | App credential you sign (MusicKit private key) — identifies **your app** to Apple                | The signed-in user’s token; not returned by `authorize()` to JS today             |
| **Music user token** | Per-user credential after sign-in — identifies **which Apple Music account** and their entitlements | The developer JWT; not interchangeable with `Authorization: Bearer`             |

**Rule of thumb:** **Library** and **History** methods refer to the user’s account. **Catalog** methods refer to the Apple Music store.

**REST headers (Apple Music API):** `Authorization: Bearer {developer JWT}` on (almost) every HTTPS call. `Music-User-Token: {music user token}` additionally for **`/v1/me/...`** (library, history, ratings, mutations, storefront). Catalog paths (`/v1/catalog/{storefront}/...`) are store-scoped and need the developer JWT; the user token is not required by Apple for anonymous catalog browse, though this module may still require prior `authorize()` on Android/web.

**App-owned music user token (multi-account):** The consuming app stores each user’s music user token (e.g. Zustand). Native does **not** persist it. `authorize()` returns the token to JS when successful. User-scoped APIs take `musicUserToken` as the **first parameter only** (never inside pagination/options objects). TypeScript and native reject missing tokens on `/v1/me/` routes.

**Developer JWT (app-level):** Signing, rotation, and delivery are **consumer app** concerns ([docs/AUTH.md](./docs/AUTH.md#production-apps-your-responsibility--not-this-library)). Pass JWTs via `Auth.authorize(developerToken)` and `Auth.setDeveloperToken(developerToken)`. Optional on iOS for `authorize()`; required on Android/web. **iOS `Catalog.search` uses native MusicKit first**; REST is fallback only.

## JS API map (by domain)

### Auth (`Auth`)

| Method                | Domain              | Purpose                                                       |
| --------------------- | ------------------- | ------------------------------------------------------------- |
| `authorize(developerToken?, options?)` | Auth | User sign-in; returns `AuthorizeResult` with optional `musicUserToken` |
| `setDeveloperToken(developerToken)` | Auth | Store developer JWT on native/web without user UI |
| `checkSubscription(musicUserToken)` | Auth / subscription | Can they play catalog, become subscriber, cloud library, etc. |
| `getStorefront(musicUserToken)` | Auth | User’s storefront id (e.g. `us`) |

**Auth documentation:** [docs/AUTH.md](./docs/AUTH.md) — developer JWT, `AuthorizeResult`, `AuthStatus`, platform requirements.

### Catalog — store (`Catalog`)

| Method                                 | Domain                     | Purpose                                      |
| -------------------------------------- | -------------------------- | -------------------------------------------- |
| `Catalog.search(term, types, options?)` | **Catalog**                | Search Apple Music store (`songs`, `albums`, `artists`, `playlists`, `stations`, `music-videos`) |
| `Catalog.getSong` / `getAlbum` / … | **Catalog**                | Fetch catalog resource by ID |
| `Catalog.getAlbumTracks` / `getArtistAlbums` / `getPlaylistTracks` | **Catalog** | Catalog relationship endpoints |
| `Catalog.getByIds(type, ids)`                  | **Catalog**          | Batch catalog GET by storefront id |
| `setPlaybackQueue(itemId, type)`       | Catalog playback (usually) | Queue catalog item by store ID               |

### Library — user account (`Library`)

| Method                                         | Domain               | Purpose                          |
| ---------------------------------------------- | -------------------- | -------------------------------- |
| `Library.getPlaylists(options?)`               | **Library**          | User’s playlists                 |
| `Library.getSongs(options?)`                   | **Library**          | User’s library songs             |
| `Library.getMusicVideos(options?)`             | **Library**          | User’s library music videos      |
| `Library.search(term, types, options?)`        | **Library**          | Search the user’s library        |
| `Library.getPlaylistTracks(playlistId, …)`     | **Library**          | Tracks in a playlist             |
| `Library.getArtists(options?)`                 | **Library**          | User’s library artists           |
| `playLibrarySong(songId)`                      | **Library playback** | Play a library song              |
| `playLibraryPlaylist(playlistId, startingAt?)` | **Library playback** | Play a library playlist          |

### History — listening (`History`)

| Method | Domain | Purpose |
| ------ | ------ | ------- |
| `History.getRecentlyPlayedResources()` | **History** | Recent albums / playlists / stations |
| `History.getRecentlyPlayedTracks(options?)` | **History** | Recent songs (listening history) |
| `History.getHeavyRotation(options?)` | **History** | Heavy rotation resources |
| `History.getRecentlyPlayedStations(options?)` | **History** | Recent radio stations |
| `History.getRecentlyAdded(options?)` | **History** | Recently added library items |
| `Library.getAlbums(options?)` | **Library** | User's library albums |

### Ratings & favorites (`Ratings`)

| Method | Domain | Purpose |
| ------ | ------ | ------- |
| `Ratings.getRating(type, id)` | **Ratings** | Like/dislike for catalog or library resource |
| `Ratings.setRating` / `clearRating` | **Ratings** | Set or remove rating (`1` / `-1`) |
| `Ratings.addToFavorites` / `removeFromFavorites` | **Ratings** | Favorites via `POST/DELETE /v1/me/favorites` |

Use `RatingResourceType` path segments (`songs`, `library-songs`, …) matching the Apple Music API.

### Recommendations (`Recommendations`)

| Method | Domain | Purpose |
| ------ | ------ | ------- |
| `Recommendations.get(options?)` | **Recommendations** | Made for You mixes / personal recommendations |
| `Recommendations.getReplay(options?)` | **Recommendations** | Replay year summaries |

Heavy rotation lives under **`History.getHeavyRotation()`** — [docs/RECOMMENDATIONS.md](./docs/RECOMMENDATIONS.md).

### Library mutations (`LibraryMutations`)

| Method | Domain | Purpose |
| ------ | ------ | ------- |
| `LibraryMutations.addToLibrary` | **Library** | Add catalog IDs to the user’s library (`POST /v1/me/library`) |
| `LibraryMutations.createPlaylist` | **Library** | Create a library playlist (optional initial tracks) |
| `LibraryMutations.addTracksToPlaylist` | **Library** | Append tracks to a library playlist |

### Playback (`Player` + hooks)

Transport controls and events — used after something is queued; not “search” or “list library.”

## Platform implementation (high level)

**iOS:** MusicKit native when possible; REST only for gaps (writes, charts, some history). **Android:** REST for data; MusicKit AAR for auth/playback.

Full per-method matrix: **[docs/PLATFORM_IMPLEMENTATION.md](./docs/PLATFORM_IMPLEMENTATION.md)**. Resource ID rules: **[docs/RESOURCE_IDS.md](./docs/RESOURCE_IDS.md)**.

| Capability            | iOS (current)                         | Android (target)                                                   |
| --------------------- | ------------------------------------- | ------------------------------------------------------------------ |
| Auth                  | `SKCloudServiceController` + MusicKit | MusicKit **Authentication** SDK (intent → Apple Music app)         |
| **Library** read APIs | Native MusicKit requests              | **Apple Music REST API** (`/v1/me/library/...`) + music user token |
| **Catalog** search    | Native `MusicCatalogSearchRequest`    | **Apple Music REST API** (`/v1/catalog/{storefront}/search`)       |
| Catalog playback      | Native player                         | `MediaPlayerController` + `CatalogPlaybackQueueItemProvider`       |
| Library playback      | Native player queue                   | REST ID resolve + playback AAR                                     |

Android requires a **developer token** at `authorize()`; iOS needs it for REST writes and gap-fill reads (stored with music user token after authorize).

Errors should be normalized to `AppleMusicError` (`code`, `message`, optional `operation`) at the native boundary where possible.

## Android delivery tiers

Priorities for Android implementation (agreed). **Tier 0** before **Tier 1**.

### Tier 0 — must have first

- `Auth.authorize()` — sign in, store music user token
- **Library read APIs** (user’s account data):
  - `getUserPlaylists`
  - `getLibrarySongs`
  - `getPlaylistSongs`
  - `getTracksFromLibrary` (if endpoint parity confirmed)

These need auth + REST client + JSON mapping to existing TS types.

### Tier 1 — important, after tier 0

- `Catalog.search()` — **store** search (not “my playlists”)
- `Auth.checkSubscription(musicUserToken)` — approximate mapping from auth/API
- Catalog playback: `setPlaybackQueue` + `Player.*` + playback events/hooks

### Tier 2 — later

- `playLibrarySong` / `playLibraryPlaylist` — library playback (validate IDs + playback SDK on device)
- Full error normalization across all paths
- Storefront / other Android config as needed

## Common mistakes to avoid

1. Calling **catalog search** “library search” or “search my playlists” — wrong domain.
2. Putting **catalog search** in tier 0 when the product need is **getUserPlaylists** / library lists — use tiers above.
3. Assuming Android MusicKit equals iOS MusicKit — Android splits auth SDK, playback SDK, and HTTP API.
4. Expecting **library playback** parity before tier 0/1 library **read** + auth are done.

## v1 direction

Full [Apple Music API](https://developer.apple.com/documentation/AppleMusicAPI) coverage before **1.0.0** — see **[docs/V1_PLAN.md](./docs/V1_PLAN.md)** (phases, domain API shape, coverage matrix, iOS REST strategy). Standalone package; no compatibility with other wrappers — [ATTRIBUTION.md](./ATTRIBUTION.md).

## Related docs

- [docs/V1_PLAN.md](./docs/V1_PLAN.md) — v1.0 completion plan
- [README.md](./README.md) — install and usage
- [docs/AUTH.md](./docs/AUTH.md) — `authorize()`, developer token, `AuthStatus`, Android auth flow
- [docs/CLI.md](./docs/CLI.md) — `yarn dev-token` (generate / verify developer JWT)
- [docs/ANDROID_IMPLEMENTATION.md](./docs/ANDROID_IMPLEMENTATION.md) — Android full iOS parity (REST + playback AAR; agent handoff)
- [docs/WEB_IMPLEMENTATION.md](./docs/WEB_IMPLEMENTATION.md) — Web parity (MusicKit JS; same REST contract as Android)
- [ATTRIBUTION.md](./ATTRIBUTION.md) — inspiration and license; no migration guide
- [docs/HISTORY.md](./docs/HISTORY.md) — history endpoints and API limits
- [docs/TYPES.md](./docs/TYPES.md) — TypeScript naming (no `I`/`T` prefixes)
