import { isLibraryId } from '../rest/library-ids';
import * as errors from './apple-music-errors';
import { WebAppleMusicApiClient } from './WebAppleMusicApiClient';
import { getMusic } from './MusicKitLoader';

type MediaType = 'song' | 'album' | 'playlist' | 'station';

function parseMediaType(type: string): MediaType {
  switch (type) {
    case 'song':
    case 'album':
    case 'playlist':
    case 'station':
      return type;
    default:
      throw errors.unknownMediaType(type);
  }
}

export class WebQueueService {
  constructor(private readonly api = new WebAppleMusicApiClient()) {}

  async setQueue(itemId: string, type: string): Promise<void> {
    const mediaType = parseMediaType(type);
    if (isLibraryId(itemId)) {
      throw errors.apiError(
        'Library queue requires a music user token. Use Player.playLibrarySong or playLibraryPlaylist.',
      );
    } else {
      await this.setCatalogQueue(itemId, mediaType);
    }
  }

  private async setCatalogQueue(itemId: string, type: MediaType): Promise<void> {
    const music = await getMusic();
    if (type === 'station') {
      await music.setQueue({ station: itemId });
      return;
    }
    await music.setQueue({ [type]: itemId });
  }

  async playLibrarySong(musicUserToken: string, songId: string): Promise<void> {
    const catalogId = await this.api.library.resolveCatalogPlaybackId(musicUserToken, songId, 'song');
    const music = await getMusic();
    await music.setQueue({ songs: [catalogId] });
  }

  async playLibraryPlaylist(musicUserToken: string, playlistId: string, startingAt: number): Promise<void> {
    const catalogIds = await this.api.library.resolveLibrarySongCatalogIds(musicUserToken, playlistId);
    if (catalogIds.length === 0) {
      throw errors.noSongsInPlaylist();
    }
    const startIndex =
      startingAt === -1 ? 0 : startingAt >= 0 && startingAt < catalogIds.length ? startingAt : 0;
    const music = await getMusic();
    await music.setQueue({ songs: catalogIds, startWith: startIndex });
  }
}
