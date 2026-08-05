import type {
  AudioSessionConfig,
  ConfigurePlayerOptions,
  PlayerType,
} from '../modules/player';

const DEFAULT_AUDIO_SESSION: Required<AudioSessionConfig> = {
  category: 'playback',
  mode: 'default',
  options: [],
  setActive: true,
};

function resolvePlayerType(options: ConfigurePlayerOptions): PlayerType | undefined {
  // Prefer friendlier `player`; keep `playerType` for backwards compatibility.
  return options.player ?? options.playerType;
}

/**
 * Normalize `configurePlayer` input for the native bridge.
 *
 * - Legacy `boolean` → `{ mixWithOthers }`
 * - `player` alias → `playerType` (native key); `player` wins if both are set
 * - Defaults: `mixWithOthers: false`; player type omitted so native keeps current/default (`application`)
 * - Top-level `mixWithOthers: true` is the common mixing knob (native also adds ducking)
 */
export function normalizePlayerConfig(
  options: boolean | ConfigurePlayerOptions = false,
): ConfigurePlayerOptions {
  if (typeof options === 'boolean') {
    return { mixWithOthers: options };
  }
  const { mixWithOthers = false, player: _player, playerType: _playerType, audioSession, ...rest } =
    options;
  const normalized: ConfigurePlayerOptions = {
    ...rest,
    mixWithOthers,
  };
  const playerType = resolvePlayerType(options);
  if (playerType !== undefined) {
    normalized.playerType = playerType;
  }
  if (audioSession !== undefined) {
    normalized.audioSession = audioSession;
  }
  return normalized;
}

function resolveStubPlayerType(options: Record<string, unknown>): PlayerType {
  const raw = options.player ?? options.playerType;
  return raw === 'system' || raw === 'application' ? raw : 'application';
}

/** Stub payload for Android/web — echo options but never claim mixing works. */
export function stubConfigurePlayerResponse(
  options: Record<string, unknown> = {},
): Record<string, unknown> {
  const playerType = resolveStubPlayerType(options);

  const incomingSession =
    options.audioSession && typeof options.audioSession === 'object'
      ? (options.audioSession as AudioSessionConfig)
      : undefined;

  const { player: _player, ...withoutPlayerAlias } = options;

  return {
    ...withoutPlayerAlias,
    playerType,
    audioSession: {
      ...DEFAULT_AUDIO_SESSION,
      ...incomingSession,
      options: incomingSession?.options ?? DEFAULT_AUDIO_SESSION.options,
    },
    // Force last: stubs do not implement AVAudioSession mixing.
    mixWithOthers: false,
  };
}
