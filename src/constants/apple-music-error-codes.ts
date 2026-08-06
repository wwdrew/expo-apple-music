/**
 * Bridge rejection codes shared across TypeScript, Android, and web.
 * Native iOS maps the same strings where {@link Exception} is thrown; other iOS
 * paths may surface {@link AppleMusicErrorCode.error} with a descriptive message.
 *
 * @see docs/ERROR_CODES.md
 */
export const AppleMusicErrorCode = {
  /** Generic failure (message carries detail). */
  error: 'ERROR',
  /** Missing or invalid auth, subscription, or HTTP 403 from Apple Music API. */
  permissionDenied: 'permissionDenied',
  /** `Auth.authorize()` on Android/web without a developer JWT. */
  missingDeveloperToken: 'MISSING_DEVELOPER_TOKEN',
  missingMusicUserToken: 'MISSING_MUSIC_USER_TOKEN',
  /** `Library` / `Player` called with a catalog id instead of `i.` / `l.` / `p.`. */
  invalidLibraryId: 'INVALID_LIBRARY_ID',
  /** Native playback queue / transport failure (Android; iOS playback events). */
  playbackError: 'PLAYBACK_ERROR',
  /** Capability permanently unavailable on this platform (e.g. Android station queue). */
  unsupportedPlatform: 'UNSUPPORTED_PLATFORM',
} as const;

export type AppleMusicErrorCode =
  (typeof AppleMusicErrorCode)[keyof typeof AppleMusicErrorCode];
