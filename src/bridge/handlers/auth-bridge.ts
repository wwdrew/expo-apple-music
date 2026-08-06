import { configureMusicKit, getMusicKitInstance } from '../../web/MusicKitLoader';
import { extractMusicUserToken } from '../../web/extract-music-user-token';
import { authStatusFromAuthorizeError, authStatusFromMusicKit } from '../../web/map-auth-status';
import * as errors from '../../web/apple-music-errors';
import type { WebAppleMusicApiClient } from '../../web/WebAppleMusicApiClient';
import type { WebSubscriptionService } from '../../web/WebSubscriptionService';
import { BridgeResponses } from '../bridge-responses';

function requireDeveloperToken(developerToken: string | null | undefined): string {
  if (!developerToken?.trim()) {
    throw errors.missingDeveloperToken();
  }
  return developerToken.trim();
}

export function createAuthBridge(api: WebAppleMusicApiClient, subscription: WebSubscriptionService) {
  return {
    async setDeveloperToken(token: string) {
      await configureMusicKit(requireDeveloperToken(token));
    },

    async authorization(
      developerToken: string | null,
      _startScreenMessage: string | null,
      _hideStartScreen: boolean | null,
    ): Promise<Record<string, string | undefined | null>> {
      const token = requireDeveloperToken(developerToken);
      const music = await configureMusicKit(token);
      if (music.isAuthorized) {
        return BridgeResponses.authorization('authorized', extractMusicUserToken(music));
      }
      try {
        const result = await music.authorize();
        const musicAfter = await getMusicKitInstance();
        const status = authStatusFromMusicKit(musicAfter, result);
        const resolvedStatus = status ?? 'unknown';
        return BridgeResponses.authorization(
          resolvedStatus,
          resolvedStatus === 'authorized'
            ? extractMusicUserToken(musicAfter, result)
            : undefined,
        );
      } catch (error) {
        return BridgeResponses.authorization(authStatusFromAuthorizeError(error), undefined);
      }
    },

    checkSubscription: (musicUserToken: string) => subscription.checkSubscription(musicUserToken),

    async getStorefront(musicUserToken: string) {
      const id = await api.getStorefront(musicUserToken);
      return BridgeResponses.storefront(id);
    },
  };
}
