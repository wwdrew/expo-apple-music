# Apple Music API coverage

Living checklist for `@wwdrew/expo-apple-music` vs the [Apple Music API](https://developer.apple.com/documentation/AppleMusicAPI). Update this file in the same PR that implements an endpoint.

**Legend:** ✅ done · 🚧 in progress · ⬜ planned · ➖ out of scope · N/A web/android/ios column = platform support

**Plan:** [V1_PLAN.md](./V1_PLAN.md)

---

## Auth & storefront

| Capability | JS API | iOS | Android | Web |
|------------|--------|-----|---------|-----|
| Authorize | `Auth.authorize(developerToken?, options?)` → `AuthorizeResult` | ✅ | ✅ | ✅ |
| Set developer JWT | `Auth.setDeveloperToken(developerToken)` | ✅ | ✅ | ✅ |
| Subscription check | `Auth.checkSubscription(musicUserToken)` | ✅ | ⚠️ inferred | ⚠️ inferred |
| Storefront | `Auth.getStorefront(musicUserToken)` | ✅ | ✅ | ✅ |

---

## Catalog (`/v1/catalog/{storefront}/...`)

| Capability | JS API | iOS | Android | Web |
|------------|--------|-----|---------|-----|
| Search (songs, albums) | `Catalog.search()` | ✅ | ✅ | ✅ |
| Search (artists, playlists, stations, music-videos) | `Catalog.search()` | ✅ | ✅ | ✅ |
| Get resource by ID | `Catalog.getSong` / `getAlbum` / `getArtist` / `getPlaylist` / `getStation` / `getMusicVideo` | ✅ | ✅ | ✅ |
| Multiple resources by ID | `Catalog.getByIds(type, ids)` | ✅ REST | ✅ REST | ✅ REST |
| Album → tracks | `Catalog.getAlbumTracks()` | ✅ | ✅ | ✅ |
| Artist → albums | `Catalog.getArtistAlbums()` | ✅ | ✅ | ✅ |
| Playlist → tracks | `Catalog.getPlaylistTracks()` | ✅ | ✅ | ✅ |
| Charts | `Catalog.getCharts()` | ✅ | ✅ | ✅ |

---

## Library (`/v1/me/library/...`)

| Capability | JS API | iOS | Android | Web |
|------------|--------|-----|---------|-----|
| List songs | `Library.getSongs()` | ✅ | ✅ | ✅ |
| List playlists | `Library.getPlaylists()` | ✅ | ✅ | ✅ |
| Playlist tracks | `Library.getPlaylistTracks()` | ✅ | ✅ | ✅ |
| List artists | `Library.getArtists()` | ✅ | ✅ | ✅ |
| List albums | `Library.getAlbums()` | ✅ | ✅ | ✅ |
| List music-videos | `Library.getMusicVideos()` | ✅ | ✅ | ✅ |
| Library search | `Library.search()` | ✅ | ✅ | ✅ |

---

## History (`/v1/me/recent/...`)

| Capability | JS API | iOS | Android | Web |
|------------|--------|-----|---------|-----|
| Recently played resources | `History.getRecentlyPlayedResources()` | ✅ | ✅ | ✅ |
| Recently played tracks | `History.getRecentlyPlayedTracks()` | ✅ | ✅ | ✅ |
| Recently played stations | `History.getRecentlyPlayedStations()` | ✅ | ✅ | ✅ |
| Heavy rotation | `History.getHeavyRotation()` | ✅ | ✅ | ✅ |
| Recently added | `History.getRecentlyAdded()` | ✅ | ✅ | ✅ |

---

## Ratings, favorites, mutations

| Capability | JS API | iOS | Android | Web |
|------------|--------|-----|---------|-----|
| Get / set / clear rating | `Ratings.getRating`, `setRating`, `clearRating` | ✅ | ✅ | ✅ |
| Favorites add / remove | `Ratings.addToFavorites`, `removeFromFavorites` | ✅ | ✅ | ✅ |
| Create library playlist | `LibraryMutations.createPlaylist` | ✅ | ✅ | ✅ |
| Add tracks to library playlist | `LibraryMutations.addTracksToPlaylist` | ✅ | ✅ | ✅ |
| Add catalog resource to library | `LibraryMutations.addToLibrary` | ✅ | ✅ | ✅ |

---

## Recommendations

| Capability | JS API | iOS | Android | Web |
|------------|--------|-----|---------|-----|
| Personal recommendations | `Recommendations.get()` | ✅ REST | ✅ REST | ✅ REST |
| Replay summaries | `Recommendations.getReplay()` | ✅ REST | ✅ REST | ✅ REST |
| Heavy rotation | `History.getHeavyRotation()` | ✅ | ✅ | ✅ |

See [RECOMMENDATIONS.md](./RECOMMENDATIONS.md). Heavy rotation is under History, not Recommendations.

---

## Playback (native SDKs, not REST)

| Capability | JS API | iOS | Android | Web |
|------------|--------|-----|---------|-----|
| Queue catalog / library | `Player.setQueue()` | ✅ | ✅ | ⚠️ |
| Configure backend / session | `Player.configurePlayer()` | ✅ | ⚠️ stub | ⚠️ stub |
| Transport + state + hooks | `Player.*` | ✅ | ✅ | ⚠️ |
| Catalog station queue | | ✅ | ➖ | ⚠️ |

Default backend is **`application`** (in-app). Prefer `{ player: 'system' }` only for Music-app / system playback on iOS. Prefer `{ mixWithOthers: true }` for mixing. Details: [PLAYBACK.md](./PLAYBACK.md).

---

## REST path reference

| Feature | HTTP |
|---------|------|
| Storefront | `GET /v1/me/storefront` |
| Catalog search | `GET /v1/catalog/{storefront}/search` |
| Catalog album tracks | `GET /v1/catalog/{storefront}/albums/{id}/tracks` |
| Catalog artist albums | `GET /v1/catalog/{storefront}/artists/{id}/albums` |
| Catalog playlist tracks | `GET /v1/catalog/{storefront}/playlists/{id}/tracks` |
| Catalog charts | `GET /v1/catalog/{storefront}/charts` |
| Library songs | `GET /v1/me/library/songs` |
| Library music-videos | `GET /v1/me/library/music-videos` |
| Library search | `GET /v1/me/library/search` |
| Catalog batch by id | `GET /v1/catalog/{storefront}/{type}?ids=` |
| Library artists | `GET /v1/me/library/artists` |
| Library playlists | `GET /v1/me/library/playlists` |
| Playlist tracks | `GET /v1/me/library/playlists/{id}/tracks` |
| Recent resources | `GET /v1/me/recent/played` |
| Recent tracks | `GET /v1/me/recent/played/tracks` |
| Recent stations | `GET /v1/me/recent/radio-stations` |
| Heavy rotation | `GET /v1/me/history/heavy-rotation` |
| Recently added | `GET /v1/me/library/recently-added` |
| Recent stations | `GET /v1/me/recent/radio-stations` |
| Library albums | `GET /v1/me/library/albums` |
| Personal rating | `GET/PUT/DELETE /v1/me/ratings/{type}/{id}` |
| Favorites | `POST/DELETE /v1/me/favorites?ids[{type}]=…` |
| Add to library | `POST /v1/me/library?ids[{type}]=…` |
| Create playlist | `POST /v1/me/library/playlists` |
| Add playlist tracks | `POST /v1/me/library/playlists/{id}/tracks` |
| Personal recommendations | `GET /v1/me/recommendations` |
| Replay | `GET /v1/me/music-summaries` |

Confirm exact heavy-rotation path against Apple docs when implementing.
