# Documentation

Guides for using **@wwdrew/expo-apple-music** in your Expo app. Browse this folder on GitHub for the full set.

## Start here

| Guide | What it covers |
| ----- | -------------- |
| **[GETTING_STARTED.md](./GETTING_STARTED.md)** | Install, config plugin, authorize, search, play — all platforms |
| **[AUTH.md](./AUTH.md)** | Developer JWT, `AuthStatus`, Android vs iOS vs web |
| **[IOS_SETUP.md](./IOS_SETUP.md)** | Portal, signing, entitlements, App Store release |
| **[CLI.md](./CLI.md)** | Mint JWTs locally (repo clone only) |

## API reference

| Guide | What it covers |
| ----- | -------------- |
| **[ERROR_CODES.md](./ERROR_CODES.md)** | `AppleMusicError` codes from the bridge |
| **[APPLE_MUSIC_API.md](./APPLE_MUSIC_API.md)** | Method coverage matrix (iOS / Android / web) |
| **[PLAYBACK.md](./PLAYBACK.md)** | `configurePlayer` defaults, `player` / mix knobs, advanced session |
| **[PLATFORM_IMPLEMENTATION.md](./PLATFORM_IMPLEMENTATION.md)** | Native vs REST per method (iOS nuances) |
| **[RESOURCE_IDS.md](./RESOURCE_IDS.md)** | Catalog vs library IDs |

## Domain notes

| Guide | What it covers |
| ----- | -------------- |
| **[HISTORY.md](./HISTORY.md)** | Recently played, heavy rotation |
| **[RECOMMENDATIONS.md](./RECOMMENDATIONS.md)** | Recommendations vs history |
| **[TYPES.md](./TYPES.md)** | TypeScript naming conventions |

## Contributors (this repo)

| Guide | What it covers |
| ----- | -------------- |
| **[BUILDING_LOCALLY.md](./BUILDING_LOCALLY.md)** | Clone, Android MusicKit `.aar` files, example app |
| [CONTEXT.md](../CONTEXT.md) | Terminology (catalog vs library) |
| [RELEASE_CHECKLIST.md](./RELEASE_CHECKLIST.md) | Pre-1.0 publish gate |
| [QA_SIGNOFF.md](./QA_SIGNOFF.md) | Manual device QA |
| [RELEASING.md](./RELEASING.md) | release-please + npm publish |
| [ANDROID_IMPLEMENTATION.md](./ANDROID_IMPLEMENTATION.md) | Android native handoff |
| [WEB_IMPLEMENTATION.md](./WEB_IMPLEMENTATION.md) | MusicKit JS bridge |
| [V1_PLAN.md](./V1_PLAN.md) | Scope and phases |
