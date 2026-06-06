# Releasing

Automated releases use **[release-please](https://github.com/googleapis/release-please)**. Manual QA still gates the first publish — see **[QA_SIGNOFF.md](./QA_SIGNOFF.md)** and **[RELEASE_CHECKLIST.md](./RELEASE_CHECKLIST.md)**.

## Before enabling automation

1. Complete **[QA_SIGNOFF.md](./QA_SIGNOFF.md)** on iOS, Android, and web.
2. Run **`yarn pack:check`** — confirms the npm tarball has no `example/`, `docs/`, `src/`, or `android/build/`.
3. Add **`NPM_TOKEN`** to GitHub repository secrets (npm automation token with publish access).

## Enable release-please

In [`.github/workflows/release-please.yml`](../.github/workflows/release-please.yml), change:

```yaml
if: false # TODO: set to true when ready to automate releases
```

to `if: true` (or remove the line).

## Flow

1. Merge conventional commits to **`main`** (`feat:`, `fix:`, `chore:`, …).
2. release-please opens a **Release PR** updating `package.json`, `.release-please-manifest.json`, and **`CHANGELOG.md`**.
3. Merge the Release PR → GitHub release + **`npm publish`** (workflow step).

Config: [`release-please-config.json`](../release-please-config.json) (node release type).

## Manual publish (one-off)

```sh
yarn test
yarn pack:check
npm publish --access public
git tag v1.0.0 && git push origin v1.0.0
```

Scoped package **`@wwdrew/expo-apple-music`** requires `--access public` on first publish.

## npm pack contents

Only runtime artifacts ship — see **`files`** in `package.json`:

- `build/` — compiled JS API
- `plugin/build/` — config plugin
- `ios/`, `android/src/main`, `android/build.gradle` (Apple `.aar` files are **not** shipped — the app provides them via the config plugin; see [GETTING_STARTED.md](./GETTING_STARTED.md))
- `app.plugin.js`, `expo-module.config.json`

Not published: `example/`, `docs/`, `src/`, tests, `scripts/`.
