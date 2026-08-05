# History API

Listening and personalization endpoints exposed via `History.*`.

## Methods

| Method | Apple endpoint | Returns |
|--------|----------------|---------|
| `getRecentlyPlayedTracks()` | `GET /v1/me/recent/played/tracks` | Songs with `artistName` — best source for “who they listen to” |
| `getRecentlyPlayedResources()` | `GET /v1/me/recent/played` (REST on iOS and Android; Apple often caps ~10 items) | Mixed albums / playlists / stations |
| `getRecentlyPlayedStations()` | `GET /v1/me/recent/radio-stations` | Radio stations |
| `getHeavyRotation()` | `GET /v1/me/history/heavy-rotation` | Mixed resources in heavy rotation — see also [RECOMMENDATIONS.md](./RECOMMENDATIONS.md) (not the same as `Recommendations.get`) |
| `getRecentlyAdded()` | `GET /v1/me/library/recently-added` | Albums / playlists recently added to library |

## Limits

- Apple does **not** expose play timestamps or full play logs on these endpoints.
- List sizes are capped by the API (pass `limit` / `offset` where supported).
- **Heavy rotation** may return an **empty list** even for active subscribers — reported intermittently on Apple’s API.

## vs `MPMediaLibrary`

`MPMediaQuery` reads the on-device media index. `History.*` reads the user’s **Apple Music account** data. Use `Library.getArtists()` for saved library artists, not play history.
