# Getting started

Minimal path to Apple Music in an Expo app (SDK 56). For auth edge cases and production JWT rotation, see **[AUTH.md](./AUTH.md)**.

## 1. Install

```sh
npx expo install @wwdrew/expo-apple-music
```

## 2. Config plugin

```ts
// app.config.ts (typed plugins — Expo SDK 56+)
import type { ExpoConfig } from 'expo/config';
import expoAppleMusic from '@wwdrew/expo-apple-music/plugin';

const config: ExpoConfig = {
  plugins: [
    expoAppleMusic({
      musicUsageDescription: 'We use Apple Music in this app.',
      // Required for Android prebuild — your app stores Apple's .aar files (not shipped on npm)
      androidMusicKitAarDir: './vendor/apple-musickit-android',
    }),
  ],
};

export default config;
```

The plugin sets **iOS deployment target 16.4** (MusicKit + Expo SDK 56 minimum). You can also use the string form `'@wwdrew/expo-apple-music'` in `plugins` if you prefer.

Then `npx expo prebuild` when you change native config.

**Apple Developer:** enable **MusicKit** on your App ID (App Services). Do **not** add MusicKit keys to entitlements — see **[IOS_SETUP.md](./IOS_SETUP.md)**.

### Android MusicKit SDK (app-owned)

Apple's MusicKit Android libraries (`.aar` files) require an Apple Developer account to download and **cannot** be redistributed in this npm package.

1. Download the **MusicKit SDK for Android** from [MusicKit on Apple Developer](https://developer.apple.com/musickit/).
2. Place both `.aar` files in a directory in your app repo (for example `./vendor/apple-musickit-android/`). Add `*.aar` to `.gitignore` if you do not commit them.
3. Set `androidMusicKitAarDir` to that path (see config above).

On Android prebuild, the plugin copies the AARs into the linked module. **Android builds fail** if the directory is missing or either file is absent. Filenames must match the SDK version this package expects:

| File | Role |
| ---- | ---- |
| `musickitauth-release-1.1.2.aar` | Authentication |
| `mediaplayback-release-1.1.1.aar` | Playback |

## 3. Developer JWT

| Platform | JWT for `Auth.authorize()` |
| -------- | -------------------------- |
| **Android** | Required |
| **Web** | Required |
| **iOS** | Optional for authorize; recommended for reliable `Catalog.search` |

Your app must **sign and serve** the JWT (backend, Remote Config, etc.). This package does not ship keys. Local dev: clone this repo and run **`yarn dev-token`** — **[CLI.md](./CLI.md)**.

## 4. Authorize and play

```ts
import {
  Auth,
  AuthStatus,
  Catalog,
  CatalogSearchType,
  Player,
} from '@wwdrew/expo-apple-music';

const developerToken = await fetchDeveloperJwtFromYourApp();

const { status, musicUserToken } = await Auth.authorize(developerToken);

if (status !== AuthStatus.AUTHORIZED || !musicUserToken) {
  return;
}

const { songs } = await Catalog.search('Beatles', [CatalogSearchType.SONGS]);
const first = songs[0];
if (first) {
  await Player.setQueue({ songs: [first] });
  await Player.play();
}
```

Refresh the JWT without re-prompting the user:

```ts
await Auth.setDeveloperToken(await fetchDeveloperJwtFromYourApp());
```

## 5. Platform checklist

### iOS

- Physical device, iOS 16.4+
- MusicKit enabled on App ID
- Optional: pass developer JWT to `Auth.authorize()` for REST catalog fallback

Details: **[IOS_SETUP.md](./IOS_SETUP.md)**

### Android

- MusicKit Android `.aar` files in `androidMusicKitAarDir` (see §2)
- Physical **ARM** device
- **Apple Music** app installed (`com.apple.android.music`)
- Active subscription
- **Developer JWT required** on `Auth.authorize(developerToken)`

### Web

- MusicKit on App ID (same portal toggle)
- Developer JWT with optional `origin` claim for localhost — **[AUTH.md](./AUTH.md)**
- Test in **Safari and Chrome** with popups allowed

## 6. Example app

This repository includes a full explorer (not published to npm).

**From a git clone:** download Apple’s Android MusicKit `.aar` files into `example/vendor/apple-musickit-android/` before Android prebuild — see **[BUILDING_LOCALLY.md](./BUILDING_LOCALLY.md)**.

```sh
git clone https://github.com/wwdrew/expo-apple-music.git
cd expo-apple-music
yarn install
# example/vendor/apple-musickit-android/*.aar — see BUILDING_LOCALLY.md
yarn dev-token -- --write-env example/.env.local
cd example && npx expo start
```

## Next steps

- **[AUTH.md](./AUTH.md)** — subscription checks, storage, errors
- **[APPLE_MUSIC_API.md](./APPLE_MUSIC_API.md)** — what works on each platform
- **[docs/README.md](./README.md)** — full doc index
