import { paginationFromMap } from '../../web/pagination';
import * as errors from '../../web/apple-music-errors';
import type { WebAppleMusicApiClient } from '../../web/WebAppleMusicApiClient';
import type { CatalogResourceType } from '../../types/catalog-resource-type';
import { BridgeResponses } from '../bridge-responses';

export function createCatalogBridge(api: WebAppleMusicApiClient) {
  const catalog = api.catalog;
  return {
    async catalogSearch(term: string, types: string[], options: Record<string, unknown>) {
      const pagination = paginationFromMap(options);
      const result = await catalog.catalogSearch(term, types, pagination.limit, pagination.offset);
      return BridgeResponses.catalogSearch(result);
    },

    getCatalogSong: (id: string) => catalog.getCatalogSong(id),
    getCatalogAlbum: (id: string) => catalog.getCatalogAlbum(id),
    getCatalogArtist: (id: string) => catalog.getCatalogArtist(id),
    getCatalogPlaylist: (id: string) => catalog.getCatalogPlaylist(id),
    getCatalogStation: (id: string) => catalog.getCatalogStation(id),
    getCatalogMusicVideo: (id: string) => catalog.getCatalogMusicVideo(id),

    async getCatalogAlbumTracks(albumId: string, options: Record<string, unknown>) {
      const pagination = paginationFromMap(options);
      const songs = await catalog.getCatalogAlbumTracks(albumId, pagination.limit, pagination.offset);
      return BridgeResponses.songs(songs);
    },

    async getCatalogArtistAlbums(artistId: string, options: Record<string, unknown>) {
      const pagination = paginationFromMap(options);
      const albums = await catalog.getCatalogArtistAlbums(artistId, pagination.limit, pagination.offset);
      return BridgeResponses.albums(albums);
    },

    async getCatalogPlaylistTracks(playlistId: string, options: Record<string, unknown>) {
      const pagination = paginationFromMap(options);
      const songs = await catalog.getCatalogPlaylistTracks(
        playlistId,
        pagination.limit,
        pagination.offset,
      );
      return BridgeResponses.songs(songs);
    },

    async getCatalogCharts(types: string[], options: Record<string, unknown>) {
      const pagination = paginationFromMap(options);
      const result = await catalog.getCatalogCharts(
        types,
        pagination.limit,
        pagination.offset,
        (options.genre as string | undefined) ?? null,
        (options.chart as string | undefined) ?? null,
      );
      return BridgeResponses.catalogCharts(result);
    },

    async getCatalogResources(type: string, ids: string[]) {
      const items = await catalog.getCatalogResources(type as CatalogResourceType, ids);
      switch (type) {
        case 'songs':
          return BridgeResponses.songs(items);
        case 'albums':
          return BridgeResponses.albums(items);
        case 'artists':
          return BridgeResponses.artists(items);
        case 'playlists':
          return BridgeResponses.playlists(items);
        case 'stations':
          return BridgeResponses.stations(items);
        case 'music-videos':
          return BridgeResponses.musicVideos(items);
        default:
          throw errors.unknownMediaType(type);
      }
    },
  };
}
