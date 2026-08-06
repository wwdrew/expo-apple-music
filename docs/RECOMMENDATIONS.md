# Recommendations & Replay

Personalized content via `Recommendations.*`. For listening history and heavy rotation, use **`History.*`** ([HISTORY.md](./HISTORY.md)).

## Methods

| Method | Endpoint / source | Notes |
|--------|-------------------|--------|
| `Recommendations.get()` | **iOS:** MusicKit `MusicPersonalRecommendationsRequest` when `ids` omitted; REST when `ids` present. **Android/web:** REST `GET /v1/me/recommendations` | Omit `ids` for all recommendations. Pass `ids` for specific `personal-recommendation` resources. |
| `Recommendations.getReplay({ year? })` | REST `GET /v1/me/music-summaries` | Latest eligible year when `year` omitted. Requires enough listening history; may error if ineligible. |

Native iOS recommendations map to the same bridge shape as REST (`title`, `resourceTypes`, nested `playlists` / `albums` / `stations`) via `MusicItemMapper` — see [PLATFORM_IMPLEMENTATION.md](./PLATFORM_IMPLEMENTATION.md), ADR-0001.

## Heavy rotation

**Not** part of `Recommendations` — use `History.getHeavyRotation()`. Same personalization domain but a different Apple endpoint; may return `[]` intermittently ([HISTORY.md](./HISTORY.md)).

## Auth

Requires an authorized user. REST paths need a **music user token** and a **developer JWT** stored at `authorize()` / `setDeveloperToken()` time ([AUTH.md](./AUTH.md)). Native MusicKit recommendations use the system MusicKit account after authorization.

## Types

- `Recommendation` — title, `resourceTypes`, and nested `playlists` / `albums` / `stations` from recommendation contents.
- `ReplaySummary` — `topSongs`, `topAlbums`, `topArtists` when Apple includes those relationships in the summary resource.
