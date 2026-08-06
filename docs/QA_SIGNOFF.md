# Manual QA sign-off (post-1.0 / next release)

One session per platform. Use the **example** app (`cd example && npx expo start`). Developer JWT in `example/.env.local` (`yarn dev-token -- --write-env example/.env.local`).

Check each box, note device/browser + date. Use this checklist for the **next** tagged release after 1.0.0 (not only the original 1.0 gate).

---

## iOS (physical device, iOS 16.4+, MusicKit on App ID)

- [ ] `Auth.authorize(developerToken)` → `authorized`
- [ ] `Catalog.search` (native MusicKit path when App ID registered)
- [ ] Tap search result → `Player.setQueue` + `play` (catalog song)
- [ ] `Library.getSongs` → play a library song
- [ ] `History.getRecentlyPlayedTracks` → play a recent track
- [ ] Transport: pause, resume, skip (if queue has entries)
- [ ] No spurious `[PlaybackController]` 404 logs during playback
- [ ] (Optional) `Catalog.search` **without** JWT — native path; or REST fallback after `authorize(developerToken)`
- [ ] (Optional) `Auth.setDeveloperToken(developerToken)` — no user re-auth UI

**Signed:** _______________ **Date:** _______________

---

## Android (physical ARM, Apple Music app installed)

- [ ] `Auth.authorize(developerToken)` → `authorized`
- [ ] `Catalog.search` → queue + play catalog song
- [ ] `Library.getSongs` → play library song
- [ ] `History.getRecentlyPlayedTracks`
- [ ] Transport: pause, play, skip
- [ ] Station queue fails with `UNSUPPORTED_PLATFORM` (expected ➖ permanent)

**Signed:** _______________ **Date:** _______________

---

## Web — Chrome (subscribed Apple ID)

- [ ] `Auth.authorize(developerToken)` — authorize **popup** allowed for origin; completes `authorized`
- [ ] `Catalog.search` → results render
- [ ] `Library.getPlaylists` / `getSongs`
- [ ] `History.getRecentlyPlayedTracks`
- [ ] Catalog song: `setQueue` + `play`
- [ ] **Soak:** leave playing **30s+**; confirm `usePlaybackState` / `useCurrentSong` stay healthy
- [ ] **Seek** (scrubber or `seekToTime`) mid-track; playback continues
- [ ] **Skip** next/previous when queue has entries
- [ ] `Player.configurePlayer({ mixWithOthers: true })` — stub echoes config; `supportedFeatures` all `false`; `mixWithOthers` remains `false` in the return ([PLAYBACK.md](./PLAYBACK.md))

**Signed:** _______________ **Date:** _______________ **Browser/build:** _______________

---

## Web — Safari (subscribed Apple ID)

Repeat the Chrome web checklist on Safari (separate sign-off — MusicKit JS / popup / autoplay differ by browser).

- [ ] Authorize popup + `authorized`
- [ ] Catalog search + library/history smoke
- [ ] Queue + play catalog song
- [ ] **Soak 30s+** with hooks updating
- [ ] Seek + skip
- [ ] `configurePlayer` stub / `supportedFeatures` expectations as above

**Signed:** _______________ **Date:** _______________ **Safari version:** _______________

---

## Publish (after platforms signed for this release)

```sh
yarn test && yarn lint && yarn pack:check
npm publish --access public
git tag vX.Y.Z && git push origin vX.Y.Z
```

See [RELEASE_CHECKLIST.md](./RELEASE_CHECKLIST.md) §7.
