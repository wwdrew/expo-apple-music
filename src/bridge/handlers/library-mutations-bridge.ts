import type { WebAppleMusicApiClient } from '../../web/WebAppleMusicApiClient';

export function createLibraryMutationsBridge(api: WebAppleMusicApiClient) {
  const libraryMutations = api.libraryMutations;
  return {
    addToLibrary: async (musicUserToken: string, resourceIds: Record<string, string[]>) => {
      await libraryMutations.addToLibrary(musicUserToken, resourceIds);
    },

    async createLibraryPlaylist(musicUserToken: string, options: Record<string, unknown>) {
      const name = String(options.name ?? '');
      const description = options.description != null ? String(options.description) : null;
      const isPublic = Boolean(options.isPublic ?? false);
      const tracks = Array.isArray(options.tracks)
        ? (options.tracks as { id: string; type: string }[])
        : null;
      return libraryMutations.createLibraryPlaylist(
        musicUserToken,
        name,
        description,
        isPublic,
        tracks,
      );
    },

    addTracksToLibraryPlaylist: async (
      musicUserToken: string,
      playlistId: string,
      tracks: { id: string; type: string }[],
    ) => {
      await libraryMutations.addTracksToLibraryPlaylist(musicUserToken, playlistId, tracks);
    },
  };
}
