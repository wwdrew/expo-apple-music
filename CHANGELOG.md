# Changelog

## [1.1.2](https://github.com/wwdrew/expo-apple-music/compare/v1.1.1...v1.1.2) (2026-06-08)


### Bug Fixes

* **release:** export app.plugin.js and harden publish pipeline ([#20](https://github.com/wwdrew/expo-apple-music/issues/20)) ([cebafe2](https://github.com/wwdrew/expo-apple-music/commit/cebafe241caf2b5cfcf457323024aa280a6c2aff))

## [1.1.1](https://github.com/wwdrew/expo-apple-music/compare/v1.1.0...v1.1.1) (2026-06-08)


### Bug Fixes

* **ci:** add workflow_dispatch to republish existing release tags ([1c59ed6](https://github.com/wwdrew/expo-apple-music/commit/1c59ed625da0b0cd89e34551399b5f698a9f2dce))
* **ci:** grant id-token write for npm provenance publish ([#15](https://github.com/wwdrew/expo-apple-music/issues/15)) ([d19c2cc](https://github.com/wwdrew/expo-apple-music/commit/d19c2cc65719be76f293ae5a3446ad26353ae81d))
* **release:** ship config plugin build output in npm tarball ([#18](https://github.com/wwdrew/expo-apple-music/issues/18)) ([85ae30c](https://github.com/wwdrew/expo-apple-music/commit/85ae30cd7b6ec6df8cc362bfcec5bc86d46c7fd4))

## [1.1.0](https://github.com/wwdrew/expo-apple-music/compare/v1.0.0...v1.1.0) (2026-06-06)


### Features

* add Library search, library music videos, and Catalog.getByIds ([64496db](https://github.com/wwdrew/expo-apple-music/commit/64496dbecacfb6cea935f0c992480aa66c9a4902))
* add shared Apple Music error code registry across platforms ([1d71757](https://github.com/wwdrew/expo-apple-music/commit/1d717578ff22592ed10d1dd53b0fb355cce64569))
* **android:** require app-owned MusicKit AARs via config plugin ([#12](https://github.com/wwdrew/expo-apple-music/issues/12)) ([cc2cc7d](https://github.com/wwdrew/expo-apple-music/commit/cc2cc7dd57c2dff9d6d98010e8bb568744ab9c5a))
* native-first iOS catalog search and optional developer JWT provider ([df62a32](https://github.com/wwdrew/expo-apple-music/commit/df62a32a72e5dd12880bd6bdbea0a325e5fa0218))
* pass music user token from app on user-scoped APIs ([803fac9](https://github.com/wwdrew/expo-apple-music/commit/803fac948dd187add87d3a42832b0ed5833de07e))


### Bug Fixes

* **android:** bind music user token for catalog playback on MediaPlayerController ([a24ba82](https://github.com/wwdrew/expo-apple-music/commit/a24ba828dbddce88bdcc4e49abb3abc9c18cb027))
* **android:** defer playback observers until developer JWT is stored ([e62e3ff](https://github.com/wwdrew/expo-apple-music/commit/e62e3ff4978080c3d9b3460ac2311678ddd5d423))
* **ci:** pin react and eslint in lockfile as devDependencies ([afda897](https://github.com/wwdrew/expo-apple-music/commit/afda897c4f6b30982b2db417ab3e18511d20e0ca))
* **example:** pass musicUserToken and wire setDeveloperToken demo ([084f626](https://github.com/wwdrew/expo-apple-music/commit/084f626327feaa35d45e33115b8a236a7770c49b))
* **ios:** restore catalog storefront and recently-played mapper ([5f6b887](https://github.com/wwdrew/expo-apple-music/commit/5f6b8877c0dc8c8d10729a57e829a4f5877e5f4c))
* reject invalid REST data arrays and harden web MusicKit envelopes ([cf4470e](https://github.com/wwdrew/expo-apple-music/commit/cf4470eb3be6cc4e4251813cbe9604ee32511252))
* restore iOS/Android builds and unify bridge error handling ([515498e](https://github.com/wwdrew/expo-apple-music/commit/515498eb6ac2572f42a898803b43f8e40285ab6d))
* surface readable API errors and Android compile imports ([19fc8ae](https://github.com/wwdrew/expo-apple-music/commit/19fc8aee0a4bb0480deb1e3b4599a5fbc633a69b))
* **web:** map MusicKit authorize() token to AuthStatus correctly ([ee60cd7](https://github.com/wwdrew/expo-apple-music/commit/ee60cd7a7857ecbf4365f07df90f692494908b05))

## 1.0.0 — 2026-05-20

First stable release of the cross-platform Apple Music API client for Expo (iOS 16+, Android, Web).

### Breaking changes

- Public API is **domain modules only** (`Auth`, `Catalog`, `Library`, `History`, `Player`, `Ratings`, `LibraryMutations`, `Recommendations`). The legacy `MusicKit` facade was removed in pre-1.0 refactors.

### Features

- **Library:** `Library.getMusicVideos()`, `Library.search()` (library-songs, library-albums, …).
- **Catalog:** `Catalog.getByIds(type, ids)` — batch storefront resource GET (`?ids=`).
- **iOS:** MusicKit playback, native library/history where available, REST for catalog gaps, ratings, mutations, and recommendations replay.
- **Android:** REST data layer + MusicKit playback AAR; developer JWT required for auth.
- **Web:** MusicKit JS bridge for auth, catalog, library, history, ratings, mutations, recommendations, and playback.
- **Catalog:** `Catalog.search`, get-by-id, relationship helpers (`getAlbumTracks`, `getArtistAlbums`, `getPlaylistTracks`), `getCharts`.
- **Example app:** Expo Router explorer with Playground (search → play), per-domain demos, and method docs.

### Bug fixes

- **iOS:** REST catalog search when a developer JWT is stored; catalog queue resolves cloud playback ids; now-playing metadata maps from the queue entry (no 404 re-fetch).
- **Android:** Playback observer survives token reset; auth and storefront resolution stabilized; REST 403 → `permissionDenied`.
- **Web:** MusicKit JS auth and catalog API in Expo web.
- **Example:** Session restore no longer auto-opens the auth flow.

### Documentation

- Platform parity table (iOS / Android / Web), [RELEASE_CHECKLIST.md](./docs/RELEASE_CHECKLIST.md), [IOS_SETUP.md](./docs/IOS_SETUP.md), [AUTH.md](./docs/AUTH.md) web section, [APPLE_MUSIC_API.md](./docs/APPLE_MUSIC_API.md) coverage matrix.

### Known limitations (1.0)

- **Android:** catalog station queue not supported (playback AAR).
- **Web / Android:** `Auth.checkSubscription()` infers flags (no native `MusicSubscription` API).
- **Web:** playback and hooks marked ⚠️ — verify in Safari + Chrome ([docs/QA_SIGNOFF.md](./docs/QA_SIGNOFF.md)).
