# TypeScript types

Naming and export conventions for `@wwdrew/expo-apple-music`.

## No `I` or `T` prefixes

Name types after what they represent — **not** with Hungarian-style prefixes:

| Avoid | Use |
|-------|-----|
| `ISong` | `Song` |
| `IAlbum` | `Album` |
| `IPaginationOptions` | `PaginationOptions` |
| `TSearchType` | `CatalogSearchType` (or a `const` object + union) |

**Interfaces and type aliases** use plain PascalCase: `Song`, `PlaybackState`, `CatalogSearch`.

**Runtime constants** use PascalCase objects when they are enums in spirit, e.g. `CatalogSearchType`, `AuthStatus`, `MusicItem`, `PlaybackStatus`.

## Response wrappers

List endpoints return a named wrapper matching the payload key:

```ts
interface ArtistsResponse {
  artists: Artist[];
}

interface RecentlyPlayedTracksResponse {
  songs: Song[];
}
```

## Alignment with native mappers

JSON from the Apple Music API is mapped in Kotlin (`AppleMusicJsonMapper`) and Swift (`MusicItemMapper` for MusicKit, `RestJsonMapper` for REST) to plain objects that match these TypeScript types. When adding a field, update **all** mapper layers.

**Bridge contract highlights:**

- `Song.duration` / `MusicVideo.duration` — **milliseconds** (number)
- `Album.trackCount` / `Playlist.trackCount` — **number**
- `Song.id` — catalog playback id when `playParams` provides one (see [RESOURCE_IDS.md](./RESOURCE_IDS.md))

Per-method native vs REST on iOS: [PLATFORM_IMPLEMENTATION.md](./PLATFORM_IMPLEMENTATION.md).

Reference mapper and fixtures for tests: `src/mappers/apple-music-json-mapper.ts`, `fixtures/*.json` (mirrored under `android/src/test/resources/fixtures/`).

## Pagination

Use `PaginationOptions` (`limit`, `offset`) for list calls. Defaults match native (typically `limit: 25`, `offset: 0`).

## Player configuration

`ConfigurePlayerOptions` uses plain names (`player`, `mixWithOthers`, `audioSession`). Prefer **`player`** over the older **`playerType`** alias (both accepted). See [PLAYBACK.md](./PLAYBACK.md).
