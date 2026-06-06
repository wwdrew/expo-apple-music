# CLI tools (repo development)

Command-line helpers for **local development** of this package. They are **not** published to npm — clone the repo and run them from the repository root.

| Script | Command | Purpose |
| ------ | ------- | ------- |
| Developer JWT | `yarn dev-token` | Sign or verify MusicKit **developer** tokens (`Auth.authorize` on every platform) |

Implementation: [`scripts/generate-developer-token.mjs`](../scripts/generate-developer-token.mjs)

---

## iOS (`Catalog.search` and local dev)

On **iOS**, a developer JWT is optional for `Auth.authorize()` (media library permission can succeed without it). Native `Catalog.search` is preferred; pass a CLI JWT only for REST fallback or Android/web. See [docs/IOS_SETUP.md](./IOS_SETUP.md).

---

## Prerequisites

1. **MusicKit key** in [Apple Developer](https://developer.apple.com/account/resources/authkeys/list) → Keys → create a key with **MusicKit** enabled.
2. Download **`AuthKey_XXXXXXXXXX.p8`** once (cannot be re-downloaded).
3. Note your **Team ID** (issuer) and **Key ID** (`kid`).

Enable **MusicKit** on your App ID if you have not already ([Identifiers](https://developer.apple.com/account/resources) → App IDs → **App Services** → MusicKit). The CLI does not configure Apple Developer for you.

Optional: set **`APPLE_MUSIC_ORIGINS`** in `.env.music` (comma-separated full URLs) to add an `origin` JWT claim on every generate — useful for web lock-down. See [AUTH.md](./AUTH.md#web-origin-optional-jwt-claim).

---

## One-time setup

```sh
cp .env.music.example .env.music
```

Edit `.env.music` (gitignored):

```env
APPLE_MUSIC_TEAM_ID=YOUR_TEAM_ID
APPLE_MUSIC_KEY_ID=YOUR_KEY_ID
APPLE_MUSIC_PRIVATE_KEY_PATH=./AuthKey_XXXXXXXXXX.p8
```

Place the `.p8` file at the path above. **Never commit** `.p8` files or long-lived JWTs (see `.gitignore`).

---

## Generate a developer token

Print a JWT to stdout (default lifetime **1 day**):

```sh
yarn dev-token
```

### Generate options

| Flag | Description |
| ---- | ----------- |
| `--team-id <id>` | Team ID (`iss` claim). Overrides `APPLE_MUSIC_TEAM_ID`. |
| `--key-id <id>` | Key ID (`kid` header). Overrides `APPLE_MUSIC_KEY_ID`. |
| `--private-key <path>` | Path to `.p8` file. Overrides `APPLE_MUSIC_PRIVATE_KEY_PATH`. |
| `--expires-in <duration>` | Lifetime: `30m`, `12h`, `1d`, etc. Default `1d`. Max ~6 months (Apple limit). |
| `--origin <url>` | Optional **`origin` JWT claim** for web (repeat flag or comma-separated). Example: `http://localhost:8081`. Omit for a token valid from any origin. |
| `--write-env <path>` | Write `EXPO_PUBLIC_APPLE_MUSIC_DEVELOPER_TOKEN=…` to a file. |

Credentials are read from **flags** or **`.env.music`** in the repo root (loaded automatically). **`APPLE_MUSIC_ORIGINS`** in `.env.music` adds an `origin` claim when `--origin` is not passed.

### Example app workflow

```sh
# 1. Mint token into the example env file (no origin claim — any localhost port)
yarn dev-token -- --write-env example/.env.local

# Web: lock token to Expo’s origin (use the port Metro prints, often 8081)
yarn dev-token -- --origin http://localhost:8081 --write-env example/.env.local

# 2. Restart Metro so Expo picks up the new env
cd example && npx expo start --clear

# 3. Run the app
cd example && npx expo run:ios
# or
cd example && npx expo run:android
# or
cd example && npx expo start --web
```

The example reads `process.env.EXPO_PUBLIC_APPLE_MUSIC_DEVELOPER_TOKEN` and passes it to `Auth.authorize(token)`. On **Android** and **web** it is required; on **iOS** it is optional (stored for REST fallback).

### Override credentials without editing `.env.music`

```sh
APPLE_MUSIC_TEAM_ID=… APPLE_MUSIC_KEY_ID=… APPLE_MUSIC_PRIVATE_KEY_PATH=./AuthKey.p8 yarn dev-token
```

---

## Verify a developer token

`Auth.authorize()` does **not** validate the JWT before opening Apple Music. Use **`--verify`** to check a token against Apple’s API **without a device**:

```sh
yarn dev-token -- --verify "<your-jwt>"
```

Verify token from the example env file:

```sh
yarn dev-token -- --verify "$(grep '^EXPO_PUBLIC_APPLE_MUSIC_DEVELOPER_TOKEN=' example/.env.local | cut -d= -f2-)"
```

### Verify options

| Flag | Description |
| ---- | ----------- |
| `--verify <jwt>` | Required. The token to check. |
| `--storefront <code>` | Catalog storefront for the test request. Default `us`. |
| `--origin <url>` | Send an `Origin` header with the test request. **Required** when the JWT includes an `origin` claim with multiple values; auto-used when the claim has exactly one value. |

### What verify does

1. **Decode** the JWT header and payload (`alg`, `kid`, `iss`, `iat`, `exp`).
2. **Warn** if expired, wrong algorithm, or missing claims.
3. **Request** `GET /v1/catalog/{storefront}/search?term=test&types=songs&limit=1` with `Authorization: Bearer <jwt>`.

| API result | Meaning |
| ---------- | ------- |
| HTTP **200** | Developer JWT is valid for Apple Music API (signature, team, key, expiry). |
| HTTP **401** / **403** | Rejected — wrong key, team ID, expired token, malformed JWT, or **`origin` claim mismatch** (pass `--origin`). |
| Decode error | Not a JWT (e.g. a random string). |

A successful verify does **not** guarantee `Auth.authorize()` returns `authorized` — you still need the user to complete the Apple Music app flow (sign-in, subscription, approval). It only confirms the **developer token** is correct.

---

## Help

```sh
yarn dev-token -- --help
# or
node scripts/generate-developer-token.mjs --help
```

---

## Security

| Do | Don’t |
| -- | ----- |
| Keep `.p8` and `.env.music` local and gitignored | Commit private keys or production tokens |
| Use short `--expires-in` for dev tokens | Ship JWTs in app binaries |
| Sign tokens on your **backend** in production | Rely on this CLI in released apps |

---

## Troubleshooting

| Problem | What to try |
| ------- | ------------- |
| `Missing credentials` | Create `.env.music` from `.env.music.example` or pass `--team-id`, `--key-id`, `--private-key`. |
| `Could not read private key` | Check `APPLE_MUSIC_PRIVATE_KEY_PATH` points at your `.p8` file. |
| Verify HTTP 401 | Regenerate with `yarn dev-token`; confirm Team ID and Key ID match the `.p8` key. If the JWT has an `origin` claim, pass `--origin` matching the claim. |
| Web auth popup 403 | Allow popups; match JWT `origin` to the browser URL (scheme + host + port); try a normal browser window. See [AUTH.md](./AUTH.md#web-origin-optional-jwt-claim). |
| Example Authorize disabled | Set `EXPO_PUBLIC_APPLE_MUSIC_DEVELOPER_TOKEN` in `example/.env.local` and restart Metro. |
| Authorize opens Apple Music but never `authorized` | Token may still be fine — verify with `--verify`; complete approval in Apple Music with an active subscription. |
| `MISSING_DEVELOPER_TOKEN` in app | Pass a non-empty string to `Auth.authorize(developerToken)` on Android. |

---

## Related

- [AUTH.md](./AUTH.md) — `Auth.authorize()`, `AuthStatus`, Android auth flow
- [README.md](../README.md) — install and usage
