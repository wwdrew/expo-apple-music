import { mapSong } from '../mappers/apple-music-json-mapper';
import type { MusicKitMediaItem } from './musickit-types';
import { getMusic, getMusicIfConfigured } from './MusicKitLoader';

const IDLE_PLAYBACK_STATE: Record<string, unknown> = {
  currentSong: undefined,
  playbackRate: 0,
  playbackStatus: 'paused',
  playbackTime: 0,
};

function mapNowPlaying(item: MusicKitMediaItem | null): Record<string, unknown> | undefined {
  if (!item) {
    return undefined;
  }
  return mapSong({
    id: item.id,
    type: item.type,
    attributes: item.attributes,
  });
}

function mapPlaybackStatus(isPlaying: boolean, playbackState: string): string {
  if (isPlaying) {
    return 'playing';
  }
  const normalized = playbackState.toLowerCase();
  if (normalized.includes('pause')) {
    return 'paused';
  }
  if (normalized.includes('stop')) {
    return 'stopped';
  }
  return 'paused';
}

export class WebPlaybackController {
  configurePlayer(options: Record<string, unknown>): Record<string, unknown> {
    return { mixWithOthers: false, ...options };
  }

  async currentState(): Promise<Record<string, unknown>> {
    const music = await getMusicIfConfigured();
    if (!music) {
      return IDLE_PLAYBACK_STATE;
    }
    const item = music.nowPlayingItem ?? music.player?.nowPlayingItem ?? null;
    const isPlaying = music.isPlaying ?? music.player?.isPlaying ?? false;
    const playbackState = music.player?.playbackState ?? '';
    const playbackTime = music.currentPlaybackTime ?? music.player?.currentPlaybackTime ?? 0;
    return {
      currentSong: mapNowPlaying(item),
      playbackRate: isPlaying ? 1 : 0,
      playbackStatus: mapPlaybackStatus(isPlaying, playbackState),
      playbackTime,
    };
  }

  async play(): Promise<void> {
    const music = await getMusic();
    await music.play();
  }

  async pause(): Promise<void> {
    const music = await getMusic();
    await music.pause();
  }

  async skipToNextEntry(): Promise<void> {
    const music = await getMusic();
    await music.skipToNextItem();
  }

  async skipToPreviousEntry(): Promise<void> {
    const music = await getMusic();
    await music.skipToPreviousItem();
  }

  async restartCurrentEntry(): Promise<void> {
    const music = await getMusic();
    if (typeof music.restart === 'function') {
      await music.restart();
      return;
    }
    await music.seekToTime(0);
  }

  async seekToTime(time: number): Promise<void> {
    const music = await getMusic();
    await music.seekToTime(time);
  }

  async togglePlayerState(): Promise<void> {
    const music = await getMusic();
    if (music.isPlaying) {
      await music.pause();
    } else {
      await music.play();
    }
  }
}
