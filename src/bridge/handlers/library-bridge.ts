import { paginationFromMap } from '../../web/pagination';
import type { WebAppleMusicApiClient } from '../../web/WebAppleMusicApiClient';
import type { LibrarySearchType } from '../../types/library-search';
import { BridgeResponses } from '../bridge-responses';

export function createLibraryBridge(api: WebAppleMusicApiClient) {
  const library = api.library;
  return {
    async getUserPlaylists(musicUserToken: string, options: Record<string, unknown>) {
      const pagination = paginationFromMap(options);
      const playlists = await library.getLibraryPlaylists(
        musicUserToken,
        pagination.limit,
        pagination.offset,
      );
      return BridgeResponses.playlists(playlists);
    },

    async getLibrarySongs(musicUserToken: string, options: Record<string, unknown>) {
      const pagination = paginationFromMap(options);
      const songs = await library.getLibrarySongs(musicUserToken, pagination.limit, pagination.offset);
      return BridgeResponses.songs(songs);
    },

    async getPlaylistSongs(musicUserToken: string, playlistId: string, _options: Record<string, unknown>) {
      const songs = await library.getPlaylistTracks(musicUserToken, playlistId);
      return BridgeResponses.songs(songs);
    },

    async getLibraryArtists(musicUserToken: string, options: Record<string, unknown>) {
      const pagination = paginationFromMap(options);
      const artists = await library.getLibraryArtists(
        musicUserToken,
        pagination.limit,
        pagination.offset,
      );
      return BridgeResponses.artists(artists);
    },

    async getLibraryAlbums(musicUserToken: string, options: Record<string, unknown>) {
      const pagination = paginationFromMap(options);
      const albums = await library.getLibraryAlbums(musicUserToken, pagination.limit, pagination.offset);
      return BridgeResponses.albums(albums);
    },

    async getLibraryMusicVideos(musicUserToken: string, options: Record<string, unknown>) {
      const pagination = paginationFromMap(options);
      const musicVideos = await library.getLibraryMusicVideos(
        musicUserToken,
        pagination.limit,
        pagination.offset,
      );
      return BridgeResponses.musicVideos(musicVideos);
    },

    async librarySearch(
      musicUserToken: string,
      term: string,
      types: string[],
      options: Record<string, unknown>,
    ) {
      const pagination = paginationFromMap(options);
      const result = await library.searchLibrary(
        musicUserToken,
        term,
        types as LibrarySearchType[],
        pagination.limit,
        pagination.offset,
      );
      return BridgeResponses.librarySearch(result);
    },
  };
}
