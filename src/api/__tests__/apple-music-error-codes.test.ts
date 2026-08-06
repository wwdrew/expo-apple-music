import { AppleMusicErrorCode } from '../../constants/apple-music-error-codes';

/** Guard against accidental renames — Android/iOS mirror these literals. */
describe('AppleMusicErrorCode', () => {
  it('matches documented bridge codes', () => {
    expect(AppleMusicErrorCode.error).toBe('ERROR');
    expect(AppleMusicErrorCode.permissionDenied).toBe('permissionDenied');
    expect(AppleMusicErrorCode.missingDeveloperToken).toBe('MISSING_DEVELOPER_TOKEN');
    expect(AppleMusicErrorCode.invalidLibraryId).toBe('INVALID_LIBRARY_ID');
    expect(AppleMusicErrorCode.playbackError).toBe('PLAYBACK_ERROR');
    expect(AppleMusicErrorCode.unsupportedPlatform).toBe('UNSUPPORTED_PLATFORM');
  });
});
