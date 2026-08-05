export type { PlaybackState } from './types/playback-state';

export * from './types/song';

export * from './types/playback-status';

export * from './types/catalog-search';

export * from './types/catalog-resource-type';

export * from './types/library-search';

export * from './types/library-music-videos';

export * from './types/album';

export * from './types/auth-status';

export type { AuthorizeResult } from './types/authorize-result';

export type { AndroidAuthorizeOptions } from './types/android-authorize-options';

export { isJwtExpired as isDeveloperTokenExpired } from './api/decode-jwt-exp';

export * from './types/check-subscription';

export * from './types/music-item';

export * from './types/tracks-from-library';

export * from './types/playlist';

export * from './types/pagination';

export * from './types/artist';

export * from './types/storefront';

export * from './types/recent-resource';

export * from './types/station';

export * from './types/music-video';

export * from './types/albums-response';

export * from './types/catalog-album-tracks';

export * from './types/catalog-charts';

export * from './types/rating';

export * from './types/library-mutations';

export * from './types/recommendation';

import useCurrentSong from './hooks/use-current-song';
import useIsPlaying from './hooks/use-is-playing';
import usePlaybackState from './hooks/use-playback-state';
import Auth from './modules/auth';
import Catalog from './modules/catalog';
import History from './modules/history';
import Library from './modules/library';
import LibraryMutations from './modules/library-mutations';
import Player from './modules/player';
import Ratings from './modules/ratings';
import Recommendations from './modules/recommendations';

export type { LibrarySongsResponse } from './modules/library';

export type { CatalogByIdsResult } from './modules/catalog';

export type { RecentlyPlayedTracksResponse } from './modules/history';

export type {
  PlayerConfig,
  PlayerType,
  AudioSessionCategory,
  AudioSessionMode,
  AudioSessionCategoryOption,
  AudioSessionConfig,
  ConfigurePlayerOptions,
  PlaybackError,
  PlaybackTimeUpdate,
  CurrentSongChangeEvent,
  PlayerEventMap,
} from './modules/player';

export { normalizePlayerConfig } from './modules/normalize-player-config';
export type { AppleMusicError } from './utils/apple-music-error';

export * from './constants/apple-music-error-codes';

export { isLibraryId } from './api/library-ids';

export { isLibraryItem } from './utils/is-library-item';

export {
  DEFAULT_PAGINATION_LIMIT,
  DEFAULT_PAGINATION_OFFSET,
  normalizePaginationOptions,
} from './api/pagination';

export { normalizeNativeError } from './api/call-native';

export { getErrorMessage } from './utils/get-error-message';

export {
  useCurrentSong,
  useIsPlaying,
  usePlaybackState,
  Auth,
  Catalog,
  History,
  Library,
  LibraryMutations,
  Player,
  Ratings,
  Recommendations,
};
