jest.mock('../../web/apple-music-errors', () => {
  const { AppleMusicErrorCode } = require('../../constants/apple-music-error-codes');
  const coded = (code: string, message: string) => Object.assign(new Error(message), { code, message });
  return {
    itemNotFound: (label: string) => coded(AppleMusicErrorCode.error, `${label} not found`),
    apiError: (message: string) => coded(AppleMusicErrorCode.error, message),
    unknownMediaType: (type: string) => coded(AppleMusicErrorCode.error, `unknown: ${type}`),
    permissionDenied: () =>
      coded(
        AppleMusicErrorCode.permissionDenied,
        'Apple Music authorization required or subscription needed (403)',
      ),
    missingTokens: () =>
      coded(
        AppleMusicErrorCode.permissionDenied,
        'Apple Music authorization required. Call Auth.authorize() first.',
      ),
  };
});

import { LibraryRestClient } from '../library-rest-client';
import type { AppleMusicRestTransport } from '../apple-music-rest-transport';
import * as errors from '../../web/apple-music-errors';

describe('LibraryRestClient', () => {
  it('getLibrarySongs calls library songs path', async () => {
    const getJson = jest.fn().mockResolvedValue({ data: [] });
    const transport: AppleMusicRestTransport = {
      getJson,
      request: jest.fn(),
    };
    const library = new LibraryRestClient(transport);

    await library.getLibrarySongs('user-token', 50, 10);

    expect(getJson).toHaveBeenCalledWith(
      '/v1/me/library/songs',
      { limit: '50', offset: '10' },
      'user-token',
    );
  });

  it('getLibraryMusicVideos calls library music-videos path', async () => {
    const getJson = jest.fn().mockResolvedValue({ data: [] });
    const library = new LibraryRestClient({ getJson, request: jest.fn() });

    await library.getLibraryMusicVideos('user-token', 25, 0);

    expect(getJson).toHaveBeenCalledWith(
      '/v1/me/library/music-videos',
      { limit: '25', offset: '0' },
      'user-token',
    );
  });

  it('searchLibrary calls library search path', async () => {
    const getJson = jest.fn().mockResolvedValue({
      results: {
        'library-songs': { data: [] },
        'library-albums': { data: [] },
        'library-artists': { data: [] },
        'library-playlists': { data: [] },
        'library-music-videos': { data: [] },
      },
    });
    const library = new LibraryRestClient({ getJson, request: jest.fn() });

    await library.searchLibrary('user-token', 'beatles', ['library-songs'], 10, 0);

    expect(getJson).toHaveBeenCalledWith(
      '/v1/me/library/search',
      {
        term: 'beatles',
        types: 'library-songs',
        limit: '10',
        offset: '0',
      },
      'user-token',
    );
  });

  describe('probeLibraryAccess', () => {
    it('returns true when the library request succeeds', async () => {
      const getJson = jest.fn().mockResolvedValue({ data: [] });
      const library = new LibraryRestClient({ getJson, request: jest.fn() });
      await expect(library.probeLibraryAccess('user-token')).resolves.toBe(true);
    });

    it('returns false on HTTP 403 permissionDenied', async () => {
      const getJson = jest.fn().mockRejectedValue(errors.permissionDenied());
      const library = new LibraryRestClient({ getJson, request: jest.fn() });
      await expect(library.probeLibraryAccess('user-token')).resolves.toBe(false);
    });

    it('rethrows network/API errors instead of treating them as false', async () => {
      const getJson = jest.fn().mockRejectedValue(errors.apiError('Apple Music API error (500)'));
      const library = new LibraryRestClient({ getJson, request: jest.fn() });
      await expect(library.probeLibraryAccess('user-token')).rejects.toThrow(/500/);
    });

    it('rethrows missing-token auth errors', async () => {
      const getJson = jest.fn().mockRejectedValue(errors.missingTokens());
      const library = new LibraryRestClient({ getJson, request: jest.fn() });
      await expect(library.probeLibraryAccess('user-token')).rejects.toThrow(/authorization required/);
    });
  });
});
