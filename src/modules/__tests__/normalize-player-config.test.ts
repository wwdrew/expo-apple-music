import {
  normalizePlayerConfig,
  stubConfigurePlayerResponse,
} from '../normalize-player-config';

describe('normalizePlayerConfig', () => {
  it('maps legacy boolean true to mixWithOthers', () => {
    expect(normalizePlayerConfig(true)).toEqual({ mixWithOthers: true });
  });

  it('maps legacy boolean false / default to mixWithOthers false', () => {
    expect(normalizePlayerConfig(false)).toEqual({ mixWithOthers: false });
    expect(normalizePlayerConfig()).toEqual({ mixWithOthers: false });
  });

  it('defaults mixWithOthers when omitted from an options object', () => {
    expect(normalizePlayerConfig({ playerType: 'system' })).toEqual({
      mixWithOthers: false,
      playerType: 'system',
    });
  });

  it('maps player alias to playerType for the bridge', () => {
    expect(normalizePlayerConfig({ player: 'system' })).toEqual({
      mixWithOthers: false,
      playerType: 'system',
    });
  });

  it('prefers player over playerType when both are set', () => {
    expect(
      normalizePlayerConfig({ player: 'application', playerType: 'system' }),
    ).toEqual({
      mixWithOthers: false,
      playerType: 'application',
    });
  });

  it('preserves audioSession and playerType', () => {
    expect(
      normalizePlayerConfig({
        mixWithOthers: true,
        playerType: 'application',
        audioSession: { category: 'playback', mode: 'spokenAudio' },
      }),
    ).toEqual({
      mixWithOthers: true,
      playerType: 'application',
      audioSession: { category: 'playback', mode: 'spokenAudio' },
    });
  });
});

describe('stubConfigurePlayerResponse', () => {
  it('forces mixWithOthers false even when caller requests true', () => {
    expect(stubConfigurePlayerResponse({ mixWithOthers: true }).mixWithOthers).toBe(false);
  });

  it('defaults playerType to application', () => {
    expect(stubConfigurePlayerResponse({}).playerType).toBe('application');
  });

  it('echoes an explicit system playerType', () => {
    expect(stubConfigurePlayerResponse({ playerType: 'system' }).playerType).toBe('system');
  });

  it('resolves player alias on stubs', () => {
    expect(stubConfigurePlayerResponse({ player: 'system' }).playerType).toBe('system');
    expect(stubConfigurePlayerResponse({ player: 'system' }).player).toBeUndefined();
  });

  it('fills a default audioSession shape', () => {
    expect(stubConfigurePlayerResponse({}).audioSession).toEqual({
      category: 'playback',
      mode: 'default',
      options: [],
      setActive: true,
    });
  });
});
