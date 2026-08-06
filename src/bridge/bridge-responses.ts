/** Standard bridge response envelopes (keys match iOS/Android native modules). */

import { stubConfigurePlayerResponse } from '../modules/normalize-player-config';

export type CatalogSearchPayload = {
  songs: unknown[];
  albums: unknown[];
  artists: unknown[];
  playlists: unknown[];
  stations: unknown[];
  musicVideos: unknown[];
};

export type CatalogChartsPayload = {
  songs: unknown[];
  albums: unknown[];
  playlists: unknown[];
  musicVideos: unknown[];
};

export type LibrarySearchPayload = {
  songs: unknown[];
  albums: unknown[];
  artists: unknown[];
  playlists: unknown[];
  musicVideos: unknown[];
};

export const BridgeResponses = {
  storefront(id: string): { id: string } {
    return { id };
  },

  authorization(
    status: string,
    musicUserToken: string | null | undefined,
  ): { status: string; musicUserToken: string | null | undefined } {
    return { status, musicUserToken };
  },

  subscription(details: {
    canPlayCatalogContent: boolean;
    canBecomeSubscriber: boolean;
    hasCloudLibraryEnabled: boolean;
    isMusicCatalogSubscriptionEligible: boolean;
  }): {
    canPlayCatalogContent: boolean;
    canBecomeSubscriber: boolean;
    hasCloudLibraryEnabled: boolean;
    isMusicCatalogSubscriptionEligible: boolean;
  } {
    return {
      canPlayCatalogContent: details.canPlayCatalogContent,
      canBecomeSubscriber: details.canBecomeSubscriber,
      hasCloudLibraryEnabled: details.hasCloudLibraryEnabled,
      isMusicCatalogSubscriptionEligible: details.isMusicCatalogSubscriptionEligible,
    };
  },

  playbackState(state: {
    playbackRate: number;
    playbackStatus: string;
    playbackTime: number;
    currentSong?: unknown;
  }): Record<string, unknown> {
    const result: Record<string, unknown> = {
      playbackRate: state.playbackRate,
      playbackStatus: state.playbackStatus,
      playbackTime: state.playbackTime,
    };
    if (state.currentSong !== undefined) {
      result.currentSong = state.currentSong;
    }
    return result;
  },

  catalogSearch(result: CatalogSearchPayload): CatalogSearchPayload {
    return {
      songs: result.songs,
      albums: result.albums,
      artists: result.artists,
      playlists: result.playlists,
      stations: result.stations,
      musicVideos: result.musicVideos,
    };
  },

  catalogCharts(result: CatalogChartsPayload): CatalogChartsPayload {
    return {
      songs: result.songs,
      albums: result.albums,
      playlists: result.playlists,
      musicVideos: result.musicVideos,
    };
  },

  librarySearch(result: LibrarySearchPayload): LibrarySearchPayload {
    return {
      songs: result.songs,
      albums: result.albums,
      artists: result.artists,
      playlists: result.playlists,
      musicVideos: result.musicVideos,
    };
  },

  musicVideos(items: unknown[]): { musicVideos: unknown[] } {
    return { musicVideos: items };
  },

  songs(items: unknown[]): { songs: unknown[] } {
    return { songs: items };
  },

  albums(items: unknown[]): { albums: unknown[] } {
    return { albums: items };
  },

  artists(items: unknown[]): { artists: unknown[] } {
    return { artists: items };
  },

  playlists(items: unknown[]): { playlists: unknown[] } {
    return { playlists: items };
  },

  stations(items: unknown[]): { stations: unknown[] } {
    return { stations: items };
  },

  recentlyPlayedResources(items: unknown[]): { recentlyPlayedItems: unknown[] } {
    return { recentlyPlayedItems: items };
  },

  recentItems(items: unknown[]): { items: unknown[] } {
    return { items: items };
  },

  recommendations(items: unknown[]): { recommendations: unknown[] } {
    return { recommendations: items };
  },

  replaySummaries(items: unknown[]): { summaries: unknown[] } {
    return { summaries: items };
  },

  configurePlayer(options: Record<string, unknown>): Record<string, unknown> {
    return stubConfigurePlayerResponse(options);
  },
} as const;
