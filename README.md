# @wwdrew/expo-apple-music

Cross-platform Apple Music API for **Expo** (SDK 56 · iOS 16.4+ · Android · Web).

Inspired by [`@lomray/react-native-apple-music`](https://github.com/Lomray-Software/react-native-apple-music) — not a drop-in replacement. See [ATTRIBUTION.md](./ATTRIBUTION.md).

## Install

```sh
npx expo install @wwdrew/expo-apple-music
```

Add the config plugin and enable **MusicKit** on your App ID in the Apple Developer portal. Full steps: **[docs/GETTING_STARTED.md](./docs/GETTING_STARTED.md)**.

```ts
// app.config.ts
import expoAppleMusic from '@wwdrew/expo-apple-music/plugin';

export default {
  plugins: [
    expoAppleMusic({ musicUsageDescription: 'We use Apple Music in this app.' }),
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
| **[Building locally](./docs/BUILDING_LOCALLY.md)** | Clone, Android `.aar` libs, example app |
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

The **example app** and Android native builds need Apple’s MusicKit Android `.aar` libraries in `android/libs/`. Those binaries are **gitignored** and are **not** in the repository — download them from Apple. Full steps: **[docs/BUILDING_LOCALLY.md](./docs/BUILDING_LOCALLY.md)**.

```sh
# After placing mediaplayback-release-1.1.1.aar and musickitauth-release-1.1.2.aar in android/libs/
yarn dev-token -- --write-env example/.env.local
cd example && npx expo start
```

## License

Apache-2.0 — [LICENSE](./LICENSE) · [NOTICE](./NOTICE)
