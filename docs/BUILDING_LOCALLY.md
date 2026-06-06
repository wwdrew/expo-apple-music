# Building locally

Steps to run this repository from a **git clone** (example app, native Android work, release dry-runs).

---

## 1. Clone and install

```sh
git clone https://github.com/wwdrew/expo-apple-music.git
cd expo-apple-music
yarn install
```

---

## 2. Apple MusicKit Android libraries (required for Android builds)

The native **authentication** and **playback** SDKs are binary `.aar` files from Apple. They **cannot** be redistributed in this npm package — your app (or this example app) must obtain them from Apple and point the config plugin at them.

### Download

1. Sign in to [Apple Developer](https://developer.apple.com/account/).
2. Enable **MusicKit** on your App ID if you have not already ([Identifiers](https://developer.apple.com/account/resources) → App IDs → **App Services** → MusicKit).
3. Download the **MusicKit SDK for Android** from [MusicKit on Apple Developer](https://developer.apple.com/musickit/) (Android section → **Download the MusicKit SDK for Android**). Sign in with your Apple Developer account if prompted.

The archive contains the authentication and media playback `.aar` libraries (exact layout may vary by SDK version).

### Install for the example app

Copy these two files into **`example/vendor/apple-musickit-android/`** (create the folder if needed):

| File | Role |
| ---- | ---- |
| `musickitauth-release-1.1.2.aar` | Authentication (Apple Music sign-in) |
| `mediaplayback-release-1.1.1.aar` | Playback (`MediaPlayerController`) |

Filenames must match `expo-module.config.json` in this package — Gradle will not resolve different names without updating that config.

Verify:

```sh
ls example/vendor/apple-musickit-android/*.aar
# mediaplayback-release-1.1.1.aar
# musickitauth-release-1.1.2.aar
```

The example [`app.config.ts`](./example/app.config.ts) sets `androidMusicKitAarDir: './vendor/apple-musickit-android'`. On `npx expo prebuild`, the config plugin copies both AARs into the linked module before Gradle runs. Without both files, Android prebuild fails with a clear error.

For your own app, use the same pattern — see **[GETTING_STARTED.md](./GETTING_STARTED.md)**.

---

## 3. Developer JWT (example app)

The example app needs a MusicKit **developer JWT** for Android and web:

```sh
yarn dev-token -- --write-env example/.env.local
```

See **[CLI.md](./CLI.md)** (`.p8` key, Team ID, Key ID). Do not commit `.env.local` or `.p8` files.

---

## 4. Run the example app

```sh
cd example
yarn install
npx expo prebuild   # after plugin, SDK upgrade, or native changes (regenerates ios/android)
npx expo run:android   # physical ARM device; Apple Music app installed
# or: npx expo start
```

Android requirements: **[AUTH.md](./AUTH.md)** (developer JWT, Apple Music app, subscription). Use a **physical ARM** device — the playback AAR has no x86 native libraries.

iOS: **[IOS_SETUP.md](./IOS_SETUP.md)** (MusicKit on App ID, signing).

---

## 5. Module development commands

From the repo root:

| Command | Purpose |
| ------- | ------- |
| `yarn build` | Compile TypeScript (`build/`) |
| `yarn lint` | ESLint |
| `yarn test` | Jest + Android bridge contract tests |

Apple `.aar` files are **not** required for `yarn build`, lint, or test — only for Android native builds via the example app prebuild.
