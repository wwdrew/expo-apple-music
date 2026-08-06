import { WebAppleMusicApiClient } from './WebAppleMusicApiClient';
import * as errors from './apple-music-errors';
import { getMusic } from './MusicKitLoader';
import { BridgeResponses } from '../bridge/bridge-responses';

export class WebSubscriptionService {
  constructor(private readonly api = new WebAppleMusicApiClient()) {}

  async checkSubscription(musicUserToken: string): Promise<Record<string, unknown>> {
    const music = await getMusic();
    if (!music.isAuthorized) {
      throw errors.missingTokens();
    }

    const libraryOk = await this.api.library.probeLibraryAccess(musicUserToken);
    const canPlay = libraryOk;

    return BridgeResponses.subscription({
      canPlayCatalogContent: canPlay,
      canBecomeSubscriber: false,
      hasCloudLibraryEnabled: libraryOk,
      isMusicCatalogSubscriptionEligible: false,
    });
  }
}
