# Silent-failure audit (1.0.0)

Audit date: 2026-05-20. Gate: [RELEASE_CHECKLIST.md](./RELEASE_CHECKLIST.md) §1 “No silent failures”.

## Policy

Bridge methods must **reject** with `AppleMusicError` (`code`, `message`, optional `operation`) on auth, HTTP, and native failures. Empty arrays/objects are allowed only when the Apple API returns a successful empty result.

## Findings

| Area | Behavior | Verdict |
|------|----------|---------|
| TypeScript `callNative` | Wraps native errors via `normalizeNativeError` | ✅ |
| iOS `AppleMusicRestClient` | Non-2xx → `RestError.apiError`; missing tokens → throw | ✅ |
| Android `AppleMusicRestTransport` | Non-2xx → `AppleMusicErrors` | ✅ |
| Web `WebAppleMusicRestTransport` | Errors propagate to `callNative` | ✅ |
| `Ratings.getRating` | HTTP 404 → `null` (no rating yet) | ✅ intentional |
| iOS `getDataArray` / `parseDataArray` | Missing or non-array `data` on list responses → `RestError` | ✅ rejects invalid shape; `data: []` → empty |
| TS `parseDataArray` / `mapTopLevelResourceArray` | Same policy on web REST stack | ✅ |
| Android `requireDataArray` | Same policy on Kotlin REST clients | ✅ |
| Web `unwrapMusicKitApiResponse` | Invalid envelope or `errors[]` in body → `CodedError` | ✅ |
| Nested search `mapResourceArray` | Optional bucket (`results.songs?.data`) → `[]`; wrong type → reject | ✅ |
| iOS `restCatalogSongResource` | Used only for queue id resolution fallback; failure → `nil` then `itemNotFound` | ✅ |
| PlaybackController metadata | Queue entry mapped first; catalog fetch is fallback only | ✅ |

## Spot-check before publish

On each platform, force a failure (revoke auth, bad JWT, airplane mode) and confirm the promise **rejects** with a readable `message`, not an empty `songs` / `playlists` array.

## Related

- [ERROR_CODES.md](./ERROR_CODES.md) — stable `code` strings for bridge rejections
- [BRIDGE_CONTRACT.md](./BRIDGE_CONTRACT.md) — fixture parity tests (`yarn test`)
- `getErrorMessage()` — format errors in app UI (never `String(error)` on bridge rejections — yields `[object Object]`)
- `callNative` throws `Error` with `code` / `operation` attached via `asThrownAppleMusicError`
