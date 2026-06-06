# `expo-apple-music` example app

Dev playground for [`@wwdrew/expo-apple-music`](../README.md).

## iOS (recommended first-time path)

1. **Apple Developer:** Create or reuse an **explicit** App ID matching `ios.bundleIdentifier` in [`app.config.ts`](./app.config.ts). Enable **MusicKit** under **App Services** only — do not add MusicKit keys to entitlements (see [docs/IOS_SETUP.md](../docs/IOS_SETUP.md)).
2. **Developer JWT:** From the **repo root** (not `example/`):
   ```sh
   cp ../.env.music.example ../.env.music   # add Team ID, Key ID, .p8 path
   yarn dev-token -- --write-env example/.env.local
   ```
3. **Run** (after plugin or SDK changes, run `npx expo prebuild` first):
   ```sh
   npx expo start --clear
   npx expo run:ios
   ```
4. Tap **Authorize**, then use **Catalog → Search.**

Without `EXPO_PUBLIC_APPLE_MUSIC_DEVELOPER_TOKEN`, iOS `Catalog.search` uses native MusicKit when your App ID is registered; a JWT is only needed for REST fallback (see [docs/IOS_SETUP.md](../docs/IOS_SETUP.md)).

## Android

1. Download Apple's MusicKit Android SDK and place both `.aar` files in `vendor/apple-musickit-android/` (see [vendor/apple-musickit-android/README.md](./vendor/apple-musickit-android/README.md)).
2. Set the same env var; Android **requires** it. See [docs/CLI.md](../docs/CLI.md).

```sh
yarn dev-token -- --write-env example/.env.local
cd example && npx expo prebuild && npx expo start --clear && npx expo run:android
```

## Web (localhost)

There is **no** “add domain” page in the Apple Developer portal for MusicKit web. Configure:

1. **App ID** — [Identifiers](https://developer.apple.com/account/resources) → `com.wwdrew.applemusic.example` → **App Services** → **MusicKit** ✓
2. **Developer JWT** — same `yarn dev-token` flow as Android ([docs/CLI.md](../docs/CLI.md))
3. **Optional origin lock** — only if you add an `origin` claim to the JWT (recommended for production, optional for local dev):

   ```sh
   # Use the exact URL Expo prints (port may differ)
   yarn dev-token -- --origin http://localhost:8081 --write-env example/.env.local
   ```

4. **Run:**

   ```sh
   cd example && npx expo start --web
   ```

5. **Browser:** allow popups for localhost; use a subscribed Apple ID; open the exact origin you minted (if using `--origin`).

If auth fails with 403 after the popup, see [docs/AUTH.md](../docs/AUTH.md#web-origin-optional-jwt-claim). As a fallback, expose the app via a tunnel (ngrok, Cloudflare Tunnel), add that HTTPS origin to `--origin`, and register nothing extra in the portal.

## Docs

- [docs/IOS_SETUP.md](../docs/IOS_SETUP.md) — full iOS signing and release checklist  
- [docs/AUTH.md](../docs/AUTH.md) — auth behavior (incl. web / localhost)  
- [docs/CLI.md](../docs/CLI.md) — `yarn dev-token`
