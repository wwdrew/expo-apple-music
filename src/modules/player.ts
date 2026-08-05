import type { EventSubscription } from 'expo-modules-core';
import { callNative } from '../api/call-native';
import { assertLibraryId } from '../api/library-ids';
import { requireMusicUserToken } from '../api/require-music-user-token';
import type { MusicItem } from '../types/music-item';
import type { PlaybackState } from '../types/playback-state';
import type { Song } from '../types/song';
import { MusicModule, musicEventEmitter } from '../native-module';
import { normalizePlayerConfig } from './normalize-player-config';

/**
 * Result of `Player.configurePlayer`.
 *
 * Default backend is **`application`** (`ApplicationMusicPlayer`) — in-app queue.
 * Pass `playerType: 'system'` only when you intentionally want Music-app / system playback.
 */
export interface PlayerConfig {
  mixWithOthers: boolean;
  playerType: PlayerType;
  audioSession?: AudioSessionConfig;
}

/** MusicKit playback backend. Default / usual choice: `application`. */
export type PlayerType = 'application' | 'system';

/** Advanced AVAudioSession category escape hatch (iOS). Prefer `mixWithOthers` for common cases. */
export type AudioSessionCategory =
  | 'ambient'
  | 'soloAmbient'
  | 'playback'
  | 'record'
  | 'playAndRecord'
  | 'multiRoute';

/** Advanced AVAudioSession mode escape hatch (iOS). */
export type AudioSessionMode =
  | 'default'
  | 'voiceChat'
  | 'videoChat'
  | 'gameChat'
  | 'videoRecording'
  | 'measurement'
  | 'moviePlayback'
  | 'spokenAudio'
  | 'voicePrompt';

/** Advanced AVAudioSession category options (iOS). */
export type AudioSessionCategoryOption =
  | 'mixWithOthers'
  | 'duckOthers'
  | 'interruptSpokenAudioAndMixWithOthers'
  | 'allowBluetooth'
  | 'allowBluetoothA2DP'
  | 'allowAirPlay'
  | 'defaultToSpeaker'
  | 'overrideMutedMicrophoneInterruption';

export interface AudioSessionConfig {
  category?: AudioSessionCategory;
  mode?: AudioSessionMode;
  options?: AudioSessionCategoryOption[];
  setActive?: boolean;
}

export interface ConfigurePlayerOptions {
  /**
   * When `true` on iOS, enables mixing and ducking with other audio.
   * Prefer this over listing `mixWithOthers` inside `audioSession.options`.
   * @default false
   */
  mixWithOthers?: boolean;
  /**
   * Playback backend (preferred name). Omit to keep the current backend (starts as `application`).
   * - `application` — in-app queue (`ApplicationMusicPlayer`)
   * - `system` — system / Music app playback (`SystemMusicPlayer`)
   *
   * Same meaning as `playerType`. If both are set, `player` wins.
   */
  player?: PlayerType;
  /**
   * Playback backend (alias of `player`). Prefer `player` in new code.
   * @see player
   */
  playerType?: PlayerType;
  /**
   * Advanced iOS `AVAudioSession` settings. Most apps only need `mixWithOthers`.
   * Defaults on iOS: category `playback`, mode `default`, `setActive: true`.
   */
  audioSession?: AudioSessionConfig;
}

export interface PlaybackTimeUpdate {
  playbackTime: number;
}

/** Payload for `onCurrentSongChange` (iOS/Android/web). */
export interface CurrentSongChangeEvent {
  currentSong?: Song;
}

export interface PlaybackError {
  message: string;
  code: number;
  domain: string;
  operation: 'play' | 'togglePlayback' | 'skipToNext' | 'skipToPrevious';
}

/** Native player event payloads keyed by event name. */
export interface PlayerEventMap {
  onPlaybackStateChange: PlaybackState;
  onCurrentSongChange: CurrentSongChangeEvent;
  onPlaybackTimeUpdate: PlaybackTimeUpdate;
  onPlaybackError: PlaybackError;
}

class Player {
  public static async setQueue(itemId: string, type: MusicItem): Promise<void> {
    await callNative('Player.setQueue', async () => {
      await MusicModule.setPlaybackQueue(itemId, type);
    });
  }

  public static async playLibrarySong(musicUserToken: string, songId: string): Promise<void> {
    requireMusicUserToken(musicUserToken, 'Player.playLibrarySong');
    assertLibraryId(songId, 'songId');
    await callNative('Player.playLibrarySong', async () => {
      await MusicModule.playLibrarySong(musicUserToken, songId);
    });
  }

  public static async playLibraryPlaylist(
    musicUserToken: string,
    playlistId: string,
    startingAt = -1,
  ): Promise<void> {
    requireMusicUserToken(musicUserToken, 'Player.playLibraryPlaylist');
    assertLibraryId(playlistId, 'playlistId');
    await callNative('Player.playLibraryPlaylist', async () => {
      await MusicModule.playLibraryPlaylist(musicUserToken, playlistId, startingAt);
    });
  }

  public static skipToNextEntry(): void {
    MusicModule.skipToNextEntry();
  }

  public static skipToPreviousEntry(): void {
    MusicModule.skipToPreviousEntry();
  }

  public static restartCurrentEntry(): void {
    MusicModule.restartCurrentEntry();
  }

  public static seekToTime(time: number): void {
    MusicModule.seekToTime(time);
  }

  public static togglePlayerState(): void {
    MusicModule.togglePlayerState();
  }

  public static play(): void {
    MusicModule.play();
  }

  public static pause(): void {
    MusicModule.pause();
  }

  public static async getCurrentState(): Promise<PlaybackState> {
    return callNative('Player.getCurrentState', async () =>
      (await MusicModule.getCurrentState()) as PlaybackState,
    );
  }

  public static addListener<K extends keyof PlayerEventMap>(
    eventType: K,
    listener: (eventData: PlayerEventMap[K]) => void,
  ): EventSubscription {
    return musicEventEmitter.addListener(eventType, listener);
  }

  public static removeAllListeners(eventType: keyof PlayerEventMap): void {
    musicEventEmitter.removeAllListeners(eventType);
  }

  /**
   * Configure the playback backend and (on iOS) the audio session.
   *
   * **Defaults** — backend `application`, exclusive playback (`mixWithOthers: false`),
   * session category `playback` / mode `default`. See [docs/PLAYBACK.md](../../docs/PLAYBACK.md).
   *
   * ```ts
   * await Player.configurePlayer();
   * await Player.configurePlayer({ mixWithOthers: true });
   * await Player.configurePlayer({ player: 'system' }); // Music app / system queue (iOS)
   * await Player.configurePlayer(true); // legacy boolean → mixWithOthers
   * ```
   *
   * Prefer `player` over `playerType` (both work). Prefer top-level `mixWithOthers`
   * over advanced `audioSession` options unless you need a specific category/mode.
   *
   * **iOS** — Applies `AVAudioSession`, then switches backend if requested. A failed
   * session config leaves the current player type unchanged.
   *
   * **Android / web** — Returns a normalized `PlayerConfig` shape; session category,
   * ducking, and focus are not fully mirrored. Do not assume iOS parity.
   */
  public static async configurePlayer(
    options: boolean | ConfigurePlayerOptions = false,
  ): Promise<PlayerConfig> {
    const normalizedOptions = normalizePlayerConfig(options);
    return callNative('Player.configurePlayer', async () =>
      (await MusicModule.configurePlayer(normalizedOptions)) as PlayerConfig,
    );
  }
}

export default Player;
