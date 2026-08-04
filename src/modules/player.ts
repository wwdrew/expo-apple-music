import type { EventSubscription } from 'expo-modules-core';
import { callNative } from '../api/call-native';
import { assertLibraryId } from '../api/library-ids';
import { requireMusicUserToken } from '../api/require-music-user-token';
import type { MusicItem } from '../types/music-item';
import type { PlaybackState } from '../types/playback-state';
import type { Song } from '../types/song';
import { MusicModule, musicEventEmitter } from '../native-module';

export interface PlayerConfig {
  mixWithOthers: boolean;
  playerType?: PlayerType;
  audioSession?: AudioSessionConfig;
}

export type PlayerType = 'application' | 'system';

export type AudioSessionCategory =
  | 'ambient'
  | 'soloAmbient'
  | 'playback'
  | 'record'
  | 'playAndRecord'
  | 'multiRoute';

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
  mixWithOthers?: boolean;
  playerType?: PlayerType;
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
   * Configure audio session / mixing behavior.
   *
   * **iOS** — Full `AVAudioSession` behavior.
   *
   * **Android / web** — Returns the same `PlayerConfig` shape; session category,
   * ducking, and focus behavior are not fully mirrored. Do not assume iOS parity.
   *
   * Accepts a legacy `boolean` (`mixWithOthers`) or an options object.
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

function normalizePlayerConfig(options: boolean | ConfigurePlayerOptions): ConfigurePlayerOptions {
  if (typeof options === 'boolean') {
    return { mixWithOthers: options };
  }
  const { mixWithOthers = false, ...rest } = options;
  return { mixWithOthers, ...rest };
}

export default Player;
