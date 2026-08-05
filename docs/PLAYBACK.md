# Playback configuration

How to configure the MusicKit player backend and (on iOS) the audio session via `Player.configurePlayer`.

## Defaults (most apps)

You can omit configuration entirely, or call with no meaningful options:

```ts
await Player.configurePlayer();
// same idea:
await Player.configurePlayer({});
await Player.configurePlayer(false); // legacy boolean → mixWithOthers: false
```

| Setting | Default |
| ------- | ------- |
| Backend | **`application`** — in-app queue (`ApplicationMusicPlayer`) |
| Mixing | Exclusive playback (`mixWithOthers: false`) |
| iOS session | category `playback`, mode `default`, `setActive: true` |

Hooks (`useCurrentSong`, `usePlaybackState`, …) and the example player bar track the **application** player.

## Common options

Prefer these top-level knobs. You rarely need anything else.

```ts
// Mix / duck with other audio (iOS)
await Player.configurePlayer({ mixWithOthers: true });

// Legacy equivalent
await Player.configurePlayer(true);

// System / Music app playback (iOS only — advanced)
await Player.configurePlayer({ player: 'system' });

// Switch back to in-app queue
await Player.configurePlayer({ player: 'application' });
```

### `player` vs `playerType`

Both select the MusicKit backend. Prefer **`player`** in app code; **`playerType`** remains supported (same values).

| Value | Meaning |
| ----- | ------- |
| `application` (default) | In-app queue |
| `system` | System / Music app queue (`SystemMusicPlayer`) |

If both are passed, **`player` wins**. The bridge always receives `playerType`.

### Return value

```ts
const config = await Player.configurePlayer({ mixWithOthers: true });
// config.playerType — 'application' | 'system'
// config.mixWithOthers — boolean (on Android/web stubs, always false)
// config.audioSession — normalized session object when present
```

## Advanced: `audioSession` (iOS)

Escape hatch for full `AVAudioSession` category / mode / options. Most apps should use top-level **`mixWithOthers`** instead of listing `'mixWithOthers'` inside `audioSession.options`.

```ts
await Player.configurePlayer({
  player: 'application',
  mixWithOthers: false,
  audioSession: {
    category: 'playback',
    mode: 'spokenAudio',
    options: ['duckOthers'],
    setActive: true,
  },
});
```

Invalid category/mode/option strings throw on iOS. Audio session is applied **before** any backend switch; if session setup fails, the current player backend is left unchanged.

## Platform notes

| Platform | Behavior |
| -------- | -------- |
| **iOS** | Full backend switch + `AVAudioSession` |
| **Android / web** | Best-effort stub: echo a normalized `PlayerConfig`. Mixing and system-player semantics are **not** mirrored. `mixWithOthers` in the return is always `false`. |

See also: [PLATFORM_IMPLEMENTATION.md](./PLATFORM_IMPLEMENTATION.md), [WEB_IMPLEMENTATION.md](./WEB_IMPLEMENTATION.md), [ANDROID_PLAYBACK.md](./ANDROID_PLAYBACK.md).
