/** Standard bridge response envelopes (keys match iOS/Android native modules). */

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
    return { mixWithOthers: false, ...options };
  },
} as const;
