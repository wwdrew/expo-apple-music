# Apple Music error codes

Stable `code` strings on bridge rejections (`AppleMusicError.code`). Use `getErrorMessage(error)` in app UI — not `String(error)`.

**Source of truth (TypeScript):** `src/constants/apple-music-error-codes.ts` — mirrored in `AppleMusicErrorCodes.kt` (Android) and `AppleMusicErrorCodes.swift` (iOS).

---

## Codes

| Code | When | iOS | Android | Web |
|------|------|-----|---------|-----|
| `ERROR` | Generic API, mapper, or native failure | ✅ (message) | ✅ | ✅ |
| `permissionDenied` | Not authorized, no subscription, HTTP **403** | ✅ REST 403 | ✅ transport | ✅ transport |
| `MISSING_DEVELOPER_TOKEN` | `Auth.authorize()` / `Auth.setDeveloperToken()` without JWT (Android/web authorize) | — | ✅ | ✅ |
| `MISSING_MUSIC_USER_TOKEN` | User-scoped API without `musicUserToken` | ✅ | ✅ | ✅ |
| `INVALID_LIBRARY_ID` | Catalog id passed to library playback/helpers | ✅ (TS pre-check) | ✅ (TS pre-check) | ✅ (TS pre-check) |
| `PLAYBACK_ERROR` | Queue / transport failure | Events (`onPlaybackError`) | ✅ | — |
| `UNSUPPORTED_PLATFORM` | Capability permanently unavailable (Android catalog **station** queue) | — | ✅ | — |

---

## Handling in app code

```ts
import {
  AppleMusicErrorCode,
  getErrorMessage,
  isAppleMusicError,
} from '@wwdrew/expo-apple-music';

try {
  await Library.getSongs();
} catch (error) {
  if (isAppleMusicError(error)) {
    switch (error.code) {
      case AppleMusicErrorCode.permissionDenied:
        // re-prompt Auth.authorize(developerToken)
        break;
      case AppleMusicErrorCode.missingDeveloperToken:
        // configure JWT (Android / web)
        break;
      default:
        console.warn(getErrorMessage(error));
    }
  }
}
```

---

## Intentional `ERROR` messages

These stay on `ERROR` so existing apps keep working; match on `message` if needed:

| Message pattern | Cause |
|-----------------|--------|
| `*not found in catalog*` / `*not found in library*` | `itemNotFound` |
| `Unknown media type:` | Invalid `Player.setQueue` type |
| `Apple Music API response missing "data"` | Invalid REST shape (hardening) |
| `Invalid MusicKit API response` | Web envelope parse failure |

Android catalog station queue uses code **`UNSUPPORTED_PLATFORM`** with message `Station playback is not supported on Android.` (permanent — MusicKit Android playback AAR has no radio).

---

## Related

- [AUTH.md](./AUTH.md) — tokens and `AuthStatus`
- [SILENT_FAILURE_AUDIT.md](./SILENT_FAILURE_AUDIT.md) — empty data vs reject policy
