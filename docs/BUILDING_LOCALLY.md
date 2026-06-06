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

The native **authentication** and **playback** SDKs are binary `.aar` files from Apple. They are **not committed to git** (see `.gitignore`). You must download them from Apple and place them in the repo before any Android build (module or example app):

### Download

1. Sign in to [Apple Developer](https://developer.apple.com/account/).
2. Enable **MusicKit** on your App ID if you have not already ([Identifiers](https://developer.apple.com/account/resources) → App IDs → **App Services** → MusicKit).
3. Download the **MusicKit SDK for Android** from [MusicKit on Apple Developer](https://developer.apple.com/musickit/) (Android section → **Download the MusicKit SDK for Android**). Sign in with your Apple Developer account if prompted.

The archive contains the authentication and media playback `.aar` libraries (exact layout may vary by SDK version).

### Install into this repo

Copy these two files into **`android/libs/`** at the repository root (create the folder if needed):

| File | Role |
| ---- | ---- |
| `musickitauth-release-1.1.2.aar` | Authentication (Apple Music sign-in) |
| `mediaplayback-release-1.1.1.aar` | Playback (`MediaPlayerController`) |

Paths must match `expo-module.config.json` — Gradle will not resolve different filenames without updating that config.

Verify:

```sh
ls android/libs/*.aar
# mediaplayback-release-1.1.1.aar
# musickitauth-release-1.1.2.aar
```

Without both files, Android builds fail (missing `:musickit-auth` / `:musickit-playback` AAR projects).

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

Before publishing, ensure both `.aar` files are in `android/libs/` per **[RELEASING.md](./RELEASING.md)**.
