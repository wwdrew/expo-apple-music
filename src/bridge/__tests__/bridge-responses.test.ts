import { BRIDGE_METHODS } from '../bridge-methods';
import { BridgeResponses } from '../bridge-responses';

describe('BridgeResponses', () => {
  it('wraps list payloads with stable keys', () => {
    expect(BridgeResponses.songs([{ id: '1' }])).toEqual({ songs: [{ id: '1' }] });
    expect(BridgeResponses.recentlyPlayedResources([])).toEqual({ recentlyPlayedItems: [] });
  });

  it('forces mixWithOthers false on configurePlayer stubs', () => {
    expect(BridgeResponses.configurePlayer({ mixWithOthers: true, playerType: 'system' })).toEqual(
      expect.objectContaining({
        mixWithOthers: false,
        playerType: 'system',
      }),
    );
  });

  it('builds auth and playback envelopes', () => {
    expect(BridgeResponses.authorization('authorized', 'tok')).toEqual({
      status: 'authorized',
      musicUserToken: 'tok',
    });
    expect(
      BridgeResponses.subscription({
        canPlayCatalogContent: true,
        canBecomeSubscriber: false,
        hasCloudLibraryEnabled: true,
        isMusicCatalogSubscriptionEligible: false,
      }),
    ).toEqual({
      canPlayCatalogContent: true,
      canBecomeSubscriber: false,
      hasCloudLibraryEnabled: true,
      isMusicCatalogSubscriptionEligible: false,
    });
    expect(
      BridgeResponses.playbackState({
        playbackRate: 1,
        playbackStatus: 'playing',
        playbackTime: 12,
        currentSong: { id: '1' },
      }),
    ).toEqual({
      playbackRate: 1,
      playbackStatus: 'playing',
      playbackTime: 12,
      currentSong: { id: '1' },
    });
  });
});

describe('BRIDGE_METHODS', () => {
  it('lists every native bridge function once', () => {
    const names = BRIDGE_METHODS.map((m) => m.nativeName);
    expect(new Set(names).size).toBe(names.length);
    expect(names).toContain('catalogSearch');
    expect(names).toContain('getRecentlyPlayedResources');
  });
});
