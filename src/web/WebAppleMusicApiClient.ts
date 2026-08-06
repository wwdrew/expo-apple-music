import { createAppleMusicRestStack } from '../rest/apple-music-rest-stack';
import { isLibraryId } from '../rest/library-ids';
import { getMusic } from './MusicKitLoader';
import { storefrontIdFromInstance } from './music-kit-api';
import { WebAppleMusicRestTransport } from './WebAppleMusicRestTransport';

/** Thin facade over shared REST domain clients (MusicKit JS transport). */
export class WebAppleMusicApiClient {
  private readonly stack = createAppleMusicRestStack(new WebAppleMusicRestTransport(), async () => {
    const music = await getMusic();
    return storefrontIdFromInstance(music);
  });

  readonly catalog = this.stack.catalog;
  readonly library = this.stack.library;
  readonly history = this.stack.history;
  readonly ratings = this.stack.ratings;
  readonly libraryMutations = this.stack.libraryMutations;
  readonly recommendations = this.stack.recommendations;
  readonly storefront = this.stack.storefront;
  readonly transport = this.stack.transport;

  static isLibraryId(id: string): boolean {
    return isLibraryId(id);
  }

  async getStorefront(musicUserToken: string): Promise<string> {
    return this.storefront.getUserStorefront(musicUserToken);
  }
}
