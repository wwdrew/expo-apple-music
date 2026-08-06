import type { WebAppleMusicApiClient } from '../../web/WebAppleMusicApiClient';

export function createRatingsBridge(api: WebAppleMusicApiClient) {
  const ratings = api.ratings;
  return {
    getRating: (musicUserToken: string, resourceType: string, id: string) =>
      ratings.getRating(musicUserToken, resourceType, id),
    setRating: (musicUserToken: string, resourceType: string, id: string, value: number) =>
      ratings.setRating(musicUserToken, resourceType, id, value),
    clearRating: async (musicUserToken: string, resourceType: string, id: string) => {
      await ratings.clearRating(musicUserToken, resourceType, id);
    },
    addToFavorites: async (musicUserToken: string, resourceIds: Record<string, string[]>) => {
      await ratings.addToFavorites(musicUserToken, resourceIds);
    },
    removeFromFavorites: async (musicUserToken: string, resourceIds: Record<string, string[]>) => {
      await ratings.removeFromFavorites(musicUserToken, resourceIds);
    },
  };
}
