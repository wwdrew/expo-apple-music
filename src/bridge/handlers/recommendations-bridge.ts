import type { WebAppleMusicApiClient } from '../../web/WebAppleMusicApiClient';
import { BridgeResponses } from '../bridge-responses';

export function createRecommendationsBridge(api: WebAppleMusicApiClient) {
  const recommendations = api.recommendations;
  return {
    async getRecommendations(musicUserToken: string, ids: string[] | null) {
      const items = await recommendations.getRecommendations(musicUserToken, ids);
      return BridgeResponses.recommendations(items);
    },

    async getReplay(musicUserToken: string, year: number | null) {
      const summaries = await recommendations.getReplay(musicUserToken, year);
      return BridgeResponses.replaySummaries(summaries);
    },
  };
}
