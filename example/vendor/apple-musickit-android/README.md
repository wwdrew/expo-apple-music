# Apple MusicKit Android SDK (app-owned)

This directory holds Apple's MusicKit Android `.aar` files for the example app. They are **not** committed to git and are **not** shipped by `@wwdrew/expo-apple-music` on npm.

## Setup

1. Sign in to [Apple Developer](https://developer.apple.com/account/).
2. Download the **MusicKit SDK for Android** from [MusicKit on Apple Developer](https://developer.apple.com/musickit/).
3. Copy these two files into **this directory**:

| File | Role |
| ---- | ---- |
| `musickitauth-release-1.1.2.aar` | Authentication |
| `mediaplayback-release-1.1.1.aar` | Playback |

4. Run `npx expo prebuild` from `example/`. The config plugin copies the AARs into the linked module before Gradle runs.

See [docs/BUILDING_LOCALLY.md](../docs/BUILDING_LOCALLY.md) for full steps.
