import { Platform } from "react-native";

/** Known permanent / stub gaps surfaced in the example demos. */
export type PlatformGapId = "androidStationQueue" | "configurePlayerFull";

export type PlatformGap = {
  id: PlatformGapId;
  /** Short badge label */
  label: string;
  /** When true, this gap applies on the current OS */
  active: boolean;
  /** Longer hint for the demo screen */
  detail: string;
};

const isAndroid = Platform.OS === "android";
const isIos = Platform.OS === "ios";

/**
 * Catalog of documented platform gaps. Keep in sync with docs/PLAYBACK.md
 * and docs/PLATFORM_IMPLEMENTATION.md.
 */
export const PLATFORM_GAPS: Record<PlatformGapId, PlatformGap> = {
  androidStationQueue: {
    id: "androidStationQueue",
    label: "Station queue unsupported",
    active: isAndroid,
    detail:
      "Android permanently rejects catalog station queues (UNSUPPORTED_PLATFORM). Use iOS or web for radio.",
  },
  configurePlayerFull: {
    id: "configurePlayerFull",
    label: "configurePlayer full support: iOS only",
    active: !isIos,
    detail:
      "Android/web echo configurePlayer options and return supportedFeatures all false. Only iOS applies AVAudioSession / SystemMusicPlayer.",
  },
};

export function activePlatformGaps(...ids: PlatformGapId[]): PlatformGap[] {
  return ids.map((id) => PLATFORM_GAPS[id]).filter((gap) => gap.active);
}
