import { paginationFromMap } from '../../web/pagination';
import type { WebAppleMusicApiClient } from '../../web/WebAppleMusicApiClient';
import { BridgeResponses } from '../bridge-responses';

export function createHistoryBridge(api: WebAppleMusicApiClient) {
  const history = api.history;
  return {
    async getRecentlyPlayedResources(musicUserToken: string) {
      const tracks = await history.getRecentlyPlayed(musicUserToken);
      return BridgeResponses.recentlyPlayedResources(tracks);
    },

    async getRecentlyPlayedTracks(musicUserToken: string, options: Record<string, unknown>) {
      const pagination = paginationFromMap(options);
      const songs = await history.getRecentlyPlayedTracks(musicUserToken, pagination.limit);
      return BridgeResponses.songs(songs);
    },

    async getHeavyRotation(musicUserToken: string, options: Record<string, unknown>) {
      const pagination = paginationFromMap(options);
      const items = await history.getHeavyRotation(musicUserToken, pagination.limit);
      return BridgeResponses.recentItems(items);
    },

    async getRecentlyPlayedStations(musicUserToken: string, options: Record<string, unknown>) {
      const pagination = paginationFromMap(options);
      const stations = await history.getRecentlyPlayedStations(musicUserToken, pagination.limit);
      return BridgeResponses.stations(stations);
    },

    async getRecentlyAdded(musicUserToken: string, options: Record<string, unknown>) {
      const pagination = paginationFromMap(options);
      const items = await history.getRecentlyAdded(musicUserToken, pagination.limit, pagination.offset);
      return BridgeResponses.recentItems(items);
    },
  };
}
