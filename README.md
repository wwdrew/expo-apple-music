# @wwdrew/expo-apple-music

Cross-platform Apple Music API for **Expo** (SDK 56 · iOS 16.4+ · Android · Web).

Inspired by [`@lomray/react-native-apple-music`](https://github.com/Lomray-Software/react-native-apple-music) — not a drop-in replacement. See [ATTRIBUTION.md](./ATTRIBUTION.md).

## Android: Apple's SDK is your responsibility

**If you target Android, you must obtain Apple's MusicKit SDK binaries yourself. This package does not include them, cannot ship them on npm, and there is no way to skip this step.**

Apple's MusicKit for Android is distributed as two proprietary `.aar` files (authentication + playback). They are gated behind an [Apple Developer](https://developer.apple.com/account/) login and **cannot be redistributed** by third-party libraries. `npx expo install @wwdrew/expo-apple-music` alone is **not** enough for Android — prebuild will fail until you:

1. **Download** the [MusicKit SDK for Android](https://developer.apple.com/musickit/) from Apple (Developer account required).
2. **Store** both `.aar` files in a directory inside **your app repo** (for example `./vendor/apple-musickit-android/` — typically gitignored).
3. **Configure** the config plugin with `androidMusicKitAarDir` pointing at that directory.

At `npx expo prebuild` for Android, the plugin copies those files into the native build. If the directory is missing or either file is absent, **the build stops with an error**. There is no stub mode, no automatic download, and no fallback.

| File | Purpose |
| --- | --- |
| `musickitauth-release-1.1.2.aar` | Apple Music sign-in |
| `mediaplayback-release-1.1.1.aar` | Playback |

**iOS and web are unaffected** — this requirement applies only to Android native builds. Full setup: **[docs/GETTING_STARTED.md](./docs/GETTING_STARTED.md)**.

## Install

```sh
npx expo install @wwdrew/expo-apple-music
```

Add the config plugin and enable **MusicKit** on your App ID in the Apple Developer portal. See **[docs/GETTING_STARTED.md](./docs/GETTING_STARTED.md)** for the full checklist (JWT, iOS entitlements, web origin, etc.).

```ts
// app.config.ts
import expoAppleMusic from '@wwdrew/expo-apple-music/plugin';

export default {
  plugins: [
    expoAppleMusic({
      musicUsageDescription: 'We use Apple Music in this app.',
      // Required for Android prebuild — see "Android: Apple's SDK is your responsibility" above
      androidMusicKitAarDir: './vendor/apple-musickit-android',
    }),
  ],
};
```

## Quick example

```ts
import { Auth, AuthStatus, Catalog, CatalogSearchType, Player } from '@wwdrew/expo-apple-music';

const developerToken = await fetchDeveloperJwtFromYourApp(); // required on Android & web

const { status, musicUserToken } = await Auth.authorize(developerToken);
if (status === AuthStatus.AUTHORIZED && musicUserToken) {
  await Catalog.search('Beatles', [CatalogSearchType.SONGS]);
  await Player.play();
}
```

**Developer JWT:** your app signs and serves it — not included in this package. Local dev: clone the repo and use `yarn dev-token` ([docs/CLI.md](./docs/CLI.md)).

## Documentation

All guides live in **[docs/](./docs/)** (browse on GitHub):

| | |
| --- | --- |
| **[Getting started](./docs/GETTING_STARTED.md)** | Install → authorize → search → play |
| **[Building locally](./docs/BUILDING_LOCALLY.md)** | Clone, example app, Android `.aar` setup |
| **[Auth](./docs/AUTH.md)** | JWT, `AuthStatus`, platform requirements |
| **[iOS setup](./docs/IOS_SETUP.md)** | Portal, signing, entitlements |
| **[API coverage](./docs/APPLE_MUSIC_API.md)** | Per-method iOS / Android / web matrix |
| **[Doc index](./docs/README.md)** | Full list |

## Platform parity (summary)

Same TypeScript API everywhere; a few features differ on Android and web.

| | iOS | Android | Web |
| --- | :---: | :---: | :---: |
| `Auth.authorize()` | ✅ | ✅ (JWT required) | ✅ (JWT required) |
| `Catalog` / `Library` / `History` | ✅ | ✅ | ✅ |
| `Player` playback | ✅ | ✅ | ⚠️ verify in Safari + Chrome |
| `Player.setQueue()` station | ✅ | ❌ | ⚠️ |
| `Auth.checkSubscription()` | ✅ | ⚠️ inferred | ⚠️ inferred |

Details: [docs/APPLE_MUSIC_API.md](./docs/APPLE_MUSIC_API.md).

## Building locally (repo clone)

Clone this repo to run the example app or contribute. The same Android SDK requirement applies: place Apple's `.aar` files in `example/vendor/apple-musickit-android/` before Android prebuild. See **[docs/BUILDING_LOCALLY.md](./docs/BUILDING_LOCALLY.md)**.

```sh
yarn dev-token -- --write-env example/.env.local
cd example && npx expo start
```

## License

Apache-2.0 — [LICENSE](./LICENSE) · [NOTICE](./NOTICE)
