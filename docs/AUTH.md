# Authentication (`Auth`)

How `Auth.authorize()` and `Auth.checkSubscription()` work on **iOS**, **Android**, and **web**, including developer tokens, return values, and device requirements.

New to the package? Start with **[GETTING_STARTED.md](./GETTING_STARTED.md)**.

## Quick start

```ts
import { Auth, AuthStatus } from '@wwdrew/expo-apple-music';

// developerToken from your app; required on Android / web, optional on iOS
const { status, musicUserToken } = await Auth.authorize(developerToken, {
  hideStartScreen: false,
  startScreenMessage: '<b>My App</b> wants to connect to Apple Music.',
});

if (status === AuthStatus.AUTHORIZED && musicUserToken) {
  const sub = await Auth.checkSubscription(musicUserToken);
}
```

iOS portal, signing, entitlements, JWT, and release: **[IOS_SETUP.md](./IOS_SETUP.md)**.

Bridge rejection codes (`permissionDenied`, `MISSING_DEVELOPER_TOKEN`, …): **[ERROR_CODES.md](./ERROR_CODES.md)**.

---

## `Auth.authorize(developerToken?, options?)`

Requests access to the user’s Apple Music account.

| Argument | iOS | Android | Web |
| -------- | --- | ------- | --- |
| `developerToken` | Optional — when provided, stored for REST; native `Catalog.search` still preferred | **Required** — pass a MusicKit developer JWT | **Required** — same as Android |
| `options` | Ignored | Optional upsell / deeplink behavior | Ignored |

Returns `Promise<AuthorizeResult>`: `{ status: AuthStatus, musicUserToken?: string }`. Store `musicUserToken` in your app (not persisted by native).

### Platform requirements

#### iOS

- **Expo SDK 56**, **iOS 16.4+**
- Config plugin with `musicUsageDescription` (sets `NSAppleMusicUsageDescription`)
- **MusicKit** enabled on your App ID in the [Apple Developer portal](https://developer.apple.com) (not added by this plugin)
- User can respond to the system media-library permission prompt

There is no separate “is Apple Music installed?” check on iOS — MusicKit is part of the OS.

#### Android

- **Apple Music** app installed (`com.apple.android.music`)
- User signed into an **Apple ID** in the Apple Music app
- An active **Apple Music subscription** (or trial) is usually required to complete auth; without it the SDK may return `restricted`
- A valid **MusicKit developer JWT** (see [Developer token](#developer-token-android))
- **Rebuild after native changes**: `npx expo prebuild` when changing the config plugin or module

The module’s Android library manifest declares `<queries>` for `com.apple.android.music` (merged into your app on build). Required for MusicKit install detection on Android 11+.

### Auth flow (Android)

1. Your app calls `Auth.authorize(developerToken, options?)`.
2. The MusicKit Authentication SDK may show a **connect / upsell** screen (unless `hideStartScreen: true`).
3. The user is sent to the **Apple Music** app to approve access.
4. Apple Music returns via deeplink; the module maps the SDK result to `AuthStatus`.
5. The **developer JWT** passed to `authorize()` is saved in app-private native storage (for playback and REST). On `authorized`, the **music user token** is returned to JavaScript in `AuthorizeResult` (your app stores it; native does not persist it).

There is **no web-based login** on Android native MusicKit — only the Apple Music app or Play Store install flow.

### Web

- **MusicKit JS v3** loaded on first `authorize()` (hosted script from Apple)
- **Developer JWT required** — same as Android; reject with `MISSING_DEVELOPER_TOKEN` if missing
- User signs in through MusicKit’s browser authorize UI (popup to `authorize.music.apple.com`; allow popups for your origin)
- Success is determined from **`music.isAuthorized`** after `music.authorize()` — the SDK return value is often a user token string, not a status label
- **Apple Developer portal:** enable **MusicKit** on your App ID ([Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources) → **Identifiers** → your App ID → **App Services** → MusicKit). There is **no** separate “add web domain” screen like Sign in with Apple — see [Web origin (optional JWT claim)](#web-origin-optional-jwt-claim) below.
- `options` (`hideStartScreen`, `startScreenMessage`) are **ignored** on web
- `checkSubscription()` uses REST inference (library probe), not `MusicSubscription.current`

See [WEB_IMPLEMENTATION.md](./WEB_IMPLEMENTATION.md).

#### Web origin (optional JWT claim)

For production web apps, Apple recommends an optional **`origin`** claim in the developer JWT — an array of allowed browser origins (full URL including scheme and port):

```json
"origin": ["https://music.example.com", "http://localhost:8081"]
```

When present, Apple rejects requests whose `Origin` header does not match a listed value. This is **not** configured in the Developer portal; you add it when signing the JWT ([Generating Developer Tokens](https://developer.apple.com/documentation/applemusicapi/generating-developer-tokens)).

| Token | Behavior |
| ----- | -------- |
| **No `origin` claim** (default from `yarn dev-token`) | Works from any origin — simplest for local dev |
| **With `origin` claim** | Must match the exact URL in the browser (e.g. `http://localhost:8081`, not `8080`) |

Mint a localhost token with the repo CLI:

```sh
yarn dev-token -- --origin http://localhost:8081 --write-env example/.env.local
```

**Local dev checklist:** use the exact origin Expo prints, allow popups, use a normal (non-private) browser window, and ensure the account has an Apple Music subscription. If auth still fails on localhost, see [CLI.md](./CLI.md) (tunnel fallback).

### Android-only options

```ts
type AndroidAuthorizeOptions = {
  /** Default `false` — show Apple’s connect screen before opening Apple Music. */
  hideStartScreen?: boolean;
  /** HTML allowed (Apple `setStartScreenMessage`). Ignored when `hideStartScreen` is true. */
  startScreenMessage?: string;
};
```

---

## Developer token (MusicKit JWT)

A **developer token** is a **signed JWT** that identifies **your app** to Apple’s services. This library **accepts** a token string when you call `Auth.authorize(developerToken)` (and can sync updates via `Auth.setDeveloperToken(developerToken)`). It does **not** mint, host, or rotate tokens for you.

| | Developer JWT | Music user token |
| - | ------------- | ---------------- |
| **What** | App credentials | Per-user token after sign-in |
| **Who creates it** | **Your app / infrastructure** (out of scope here) | Returned by `authorize()` on success |
| **Used for** | Starting Android auth; REST; optional iOS REST fallback | Library REST (`/v1/me/...`) |
| **Passed to** | `Auth.authorize(developerToken)` — you supply the string | App-owned: first arg on user-scoped APIs |

On **iOS**, the developer token is **optional** for `authorize()` (media-library permission can succeed without it). **`Catalog.search` uses native MusicKit first**; REST is only a fallback when auto-token fails and a developer JWT is already stored. Enable **MusicKit** on your App ID so native catalog search works without a manual JWT.

### Production apps (your responsibility — not this library)

Document and implement this in **your** shipping app. The checklist below is guidance for integrators; `@wwdrew/expo-apple-music` only requires a valid JWT string at the API boundary.

| Topic | What you do | What this package does |
| ----- | ----------- | ---------------------- |
| **Signing** | Hold the MusicKit `.p8` key off-device; sign JWTs (server, Cloud Function, CI, etc.) | Nothing |
| **Lifetime** | Apple max ~**6 months** per JWT; plan rotation before `exp` | Nothing (optional `isDeveloperTokenExpired()` helper in JS) |
| **Delivery** | HTTPS endpoint, Remote Config, manual ops — your choice | You pass the string to `authorize` / `setDeveloperToken` |
| **Storage** | Your policy (memory-only, Keychain, refetch every time) | Copies into native / MusicKit JS when you pass a token |
| **User re-auth** | Developer JWT refresh must **not** force Apple Music sign-in again | `setDeveloperToken(jwt)` syncs only; `authorize(jwt)` is for the **user** |

**Do not** embed the `.p8` private key or a non-rotating JWT in the app binary. Fetch or mint a JWT in **your** app, then pass it in.

See Apple: [Generating developer tokens](https://developer.apple.com/documentation/applemusicapi/generating_developer_tokens). Local dev: [CLI.md](./CLI.md) (repo-only; not for production signing).

### API (you pass the JWT)

```ts
import { Auth, AuthStatus, isDeveloperTokenExpired } from '@wwdrew/expo-apple-music';

async function getDeveloperJwtFromYourApp(): Promise<string> {
  const res = await fetch('https://your.app/api/apple-music/developer-token');
  const { token } = await res.json();
  return token;
}

// First sign-in (Android/web: developerToken required)
const jwt = await getDeveloperJwtFromYourApp();
const { status, musicUserToken } = await Auth.authorize(jwt);

// Later: rotate developer JWT without re-prompting the user
const freshJwt = await getDeveloperJwtFromYourApp();
await Auth.setDeveloperToken(freshJwt);
```

| Method | Purpose |
| ------ | ------- |
| `Auth.authorize(developerToken?, options?)` | User sign-in; stores developer JWT on native/web when provided |
| `Auth.setDeveloperToken(developerToken)` | Replace stored developer JWT only (no Apple Music UI) |

Optional export `isDeveloperTokenExpired(token)` decodes JWT `exp` so **your** app can decide when to fetch a new token.

**Security (your app):** The JWT is weaker than the `.p8` key but still identifies your app — disclose and protect per your threat model.

### Native session (iOS / Android)

The module **persists the developer JWT** in native storage when you pass it (for REST, Android auth, and optional iOS REST fallback). The **music user token is not persisted** — your app passes it per call.

**Repo CLI (local dev / example app only)**

See **[docs/CLI.md](./CLI.md)** for setup (`.env.music`), generating tokens, and `--verify` to test a JWT without the Apple Music app.

Quick start:

```sh
cp .env.music.example .env.music   # add Team ID, Key ID, .p8 path
yarn dev-token -- --write-env example/.env.local
yarn dev-token -- --verify "$(grep EXPO_PUBLIC example/.env.local | cut -d= -f2-)"
```

`Auth.authorize()` does **not** validate the developer JWT before opening Apple Music — use the CLI `--verify` flag or complete the in-app flow and check for `authorized`.

### Missing or invalid token

| Situation | Result |
| --------- | ------ |
| No `developerToken` on Android/web | Promise **rejects** with `MISSING_DEVELOPER_TOKEN` |
| Invalid / expired JWT | `AuthStatus.UNKNOWN` (`TOKEN_FETCH_ERROR` from SDK) |

When a JWT expires, Apple returns **401** on REST calls. Fetch a new token in your app and call `Auth.setDeveloperToken(freshJwt)` (or `authorize(freshJwt)` if you also need user auth).

Apple’s reference: [Creating a developer token](https://developer.apple.com/documentation/applemusicapi/generating_developer_tokens) and [Android MusicKit](https://developer.apple.com/documentation/musickit/android).

---

## `AuthStatus` return values

Same values on **iOS** and **Android**. Import `AuthStatus` for constants.

| Value | Meaning | Typical cause |
| ----- | ------- | ------------- |
| `authorized` | User completed auth; `musicUserToken` in `AuthorizeResult` when available | Success |
| `denied` | User did not complete auth (dismissed upsell, cancelled in Apple Music, declined iOS prompt) | User action |
| `notDetermined` | Permission not requested yet | iOS before first `authorize()` |
| `restricted` | Account cannot use Apple Music for this flow | Android: no/expired subscription; iOS: parental / device restrictions |
| `unknown` | Error or unrecognized SDK result | Bad developer token, `TOKEN_FETCH_ERROR`, unexpected SDK state |

### Mapping notes (Android)

The MusicKit Authentication SDK uses its own error codes; this module normalizes them to match iOS:

| SDK signal | `AuthStatus` |
| ---------- | ------------ |
| `USER_CANCELLED`, upsell close, Apple Music cancel, empty token | `denied` |
| `NO_SUBSCRIPTION`, `SUBSCRIPTION_EXPIRED` | `restricted` |
| `TOKEN_FETCH_ERROR` | `unknown` |
| Intent with no token/error extras (`UNKNOWN`) | `denied` (user-backed-out) |

**There is no separate `cancelled` status** — user dismissal is always `denied`, matching iOS `SKCloudServiceController` behavior.

### Recommended handling

```ts
import { Auth, AuthStatus } from '@wwdrew/expo-apple-music';

const { status, musicUserToken } = await Auth.authorize(developerToken);

switch (status) {
  case AuthStatus.AUTHORIZED:
    if (musicUserToken) {
      // Store in your app state (e.g. Zustand)
    }
    break;
  case AuthStatus.DENIED:
    // User closed upsell or Apple Music, or declined iOS prompt
    break;
  case AuthStatus.RESTRICTED:
    // Offer Apple Music subscription / trial
    break;
  case AuthStatus.NOT_DETERMINED:
    // iOS: call authorize() again when appropriate
    break;
  case AuthStatus.UNKNOWN:
    // Log; retry with fresh developer token on Android
    break;
}
```

---

## `Auth.checkSubscription()`

**iOS** calls `MusicSubscription.current` and returns:

| Field | Meaning |
| ----- | ------- |
| `canPlayCatalogContent` | User can play catalog with a music player |
| `canBecomeSubscriber` | User can be offered a subscription |
| `hasCloudLibraryEnabled` | Cloud library modifications allowed |
| `isMusicCatalogSubscriptionEligible` | Same as `canBecomeSubscriber` (compat) |

On **Android and web**, the call returns best-effort flags inferred from authorization + library access (see [WEB_IMPLEMENTATION.md](./WEB_IMPLEMENTATION.md#checksubscription-on-web)).

Requires `musicUserToken` from `authorize()` (first parameter).

Typical flow after auth:

```ts
if (status !== AuthStatus.AUTHORIZED || !musicUserToken) return;

const sub = await Auth.checkSubscription(musicUserToken);
if (!sub.canPlayCatalogContent) {
  // Prompt subscription / trial
}
```

There is **no** `Auth.isAvailable()` — use `authorize()` + `checkSubscription()` (iOS) instead.

---

## iOS troubleshooting (MusicKit / signing)

**Full walkthrough:** **[IOS_SETUP.md](./IOS_SETUP.md)** (portal, entitlements mistakes, signing, developer JWT, release checklist).

Short version: MusicKit is an **App Service** on your App ID — not a MusicKit row in Xcode Capabilities and **not** an entitlement you expect inside the provisioning profile ([Apple DTS](https://developer.apple.com/forums/thread/799000)). Do **not** add `com.apple.developer.applemusickit` / `musickit` to entitlements; that breaks automatic signing. Prefer native `Catalog.search` with MusicKit enabled on the App ID; use a developer JWT only when you need REST fallback or Android/web ([§Production apps](#production-apps-your-responsibility--not-this-library)).

| Symptom | What to do |
| ------- | ---------- |
| Xcode: profile missing `applemusickit` / `musickit` | Remove those keys from entitlements — see **Entitlements** in [IOS_SETUP.md](./IOS_SETUP.md). |
| Catalog search `404` / “Client not found” | Pass developer JWT + `authorize()`; restart Metro after `.env.local` — see **Developer JWT** in [IOS_SETUP.md](./IOS_SETUP.md). |
| Profile “won’t create” after adding MusicKit to entitlements | Remove bogus entitlement keys; MusicKit is not provisioned that way. |

---

## Config plugin reference

Import from `@wwdrew/expo-apple-music/plugin` for typed options (Expo SDK 56+). The plugin sets **iOS deployment target 16.4**.

```ts
type ExpoAppleMusicPluginProps = {
  /** iOS — NSAppleMusicUsageDescription */
  musicUsageDescription?: string;
};
```

---

## Related

- [README.md](../README.md) — install
- [IOS_SETUP.md](./IOS_SETUP.md) — **iOS**: signing, Apple Developer portal, JWT, release checklist
- [CONTEXT.md](../CONTEXT.md) — catalog vs library, Android tiers
- [ATTRIBUTION.md](../ATTRIBUTION.md) — inspiration and license (no migration guide)
