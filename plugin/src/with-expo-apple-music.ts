import path from "path";

import {
  type ConfigPlugin,
  IOSConfig,
  withAndroidManifest,
  withDangerousMod,
  withInfoPlist,
  withXcodeProject,
} from "@expo/config-plugins";

import { copyAndroidMusicKitAars } from "./apple-music-aars";

/** plugin/build/*.js → package root */
function getExpoAppleMusicModuleRoot(): string {
  return path.join(__dirname, "..", "..");
}

/** MusicKit APIs used by this module require iOS 16.4+ (Expo SDK 56 minimum). */
const IOS_DEPLOYMENT_TARGET = "16.4";

const withIosDeploymentTargetPodfile =
  IOSConfig.BuildProperties.createBuildPodfilePropsConfigPlugin(
    [
      {
        propName: "ios.deploymentTarget",
        propValueGetter: () => IOS_DEPLOYMENT_TARGET,
      },
    ],
    "withExpoAppleMusicIosDeploymentTargetPodfile",
  );

const withIosDeploymentTargetXcodeProject: ConfigPlugin = (config) => {
  return withXcodeProject(config, (c) => {
    const { Target, XcodeUtils } = IOSConfig;
    const project = c.modResults;
    const targetBuildConfigListIds = Target.getNativeTargets(project)
      .filter(([_, target]) =>
        Target.isTargetOfType(target, Target.TargetType.APPLICATION),
      )
      .map(([_, target]) => target.buildConfigurationList);

    for (const buildConfigListId of targetBuildConfigListIds) {
      for (const [, configurations] of XcodeUtils.getBuildConfigurationsForListId(
        project,
        buildConfigListId,
      )) {
        const { buildSettings } = configurations;
        if (buildSettings?.IPHONEOS_DEPLOYMENT_TARGET) {
          buildSettings.IPHONEOS_DEPLOYMENT_TARGET = IOS_DEPLOYMENT_TARGET;
        }
      }
    }
    return c;
  });
};

export const DEFAULT_MUSIC_USAGE =
  "Allow $(PRODUCT_NAME) to access Apple Music.";

export type ExpoAppleMusicPluginProps = {
  /**
   * Sets `NSAppleMusicUsageDescription` in the generated iOS Info.plist.
   */
  musicUsageDescription?: string;
  /**
   * Directory containing Apple's MusicKit Android `.aar` files (path relative to
   * the app project root). Required when running `expo prebuild` for Android.
   *
   * The plugin copies the AARs into this package at prebuild time — they are not
   * shipped on npm and cannot be redistributed by this library.
   */
  androidMusicKitAarDir?: string;
};

const ALLOW_BACKUP_REPLACE_KEY = "android:allowBackup";

/** musickitauth AAR sets allowBackup=true; host apps may differ — merge via tools:replace. */
const withAndroidAllowBackupToolsReplace: ConfigPlugin = (config) => {
  return withAndroidManifest(config, (c) => {
    const mainApplication = c.modResults?.manifest?.application?.[0];
    if (!mainApplication?.$) {
      return c;
    }

    const existing = mainApplication.$["tools:replace"];
    if (!existing) {
      mainApplication.$["tools:replace"] = ALLOW_BACKUP_REPLACE_KEY;
      return c;
    }

    const keys = [
      ...new Set(
        existing
          .split(",")
          .map((key) => key.trim())
          .filter(Boolean),
      ),
    ];
    if (!keys.includes(ALLOW_BACKUP_REPLACE_KEY)) {
      keys.push(ALLOW_BACKUP_REPLACE_KEY);
    }
    mainApplication.$["tools:replace"] = keys.join(",");

    return c;
  });
};

const withAndroidMusicKitAars: ConfigPlugin<
  Pick<ExpoAppleMusicPluginProps, "androidMusicKitAarDir">
> = (config, { androidMusicKitAarDir } = {}) => {
  return withDangerousMod(config, [
    "android",
    async (config) => {
      const configuredDir = androidMusicKitAarDir?.trim();
      if (!configuredDir) {
        throw new Error(
          "[expo-apple-music] `androidMusicKitAarDir` is required for Android builds. " +
            "Download Apple's MusicKit SDK for Android, place the .aar files in a directory " +
            "in your app (for example `./vendor/apple-musickit-android`), and pass that path " +
            "to the expo-apple-music config plugin. See docs/GETTING_STARTED.md.",
        );
      }

      const projectRoot = config.modRequest.projectRoot;
      const sourceDir = path.resolve(projectRoot, configuredDir);
      const moduleRoot = getExpoAppleMusicModuleRoot();

      copyAndroidMusicKitAars({ sourceDir, moduleRoot });

      return config;
    },
  ]);
};

const withExpoAppleMusic: ConfigPlugin<ExpoAppleMusicPluginProps | void> = (
  config,
  props,
) => {
  const { musicUsageDescription, androidMusicKitAarDir } = props ?? {};

  config = withIosDeploymentTargetPodfile(config);
  config = withIosDeploymentTargetXcodeProject(config);
  config = withAndroidMusicKitAars(config, { androidMusicKitAarDir });
  config = withAndroidAllowBackupToolsReplace(config);

  return withInfoPlist(config, (c) => {
    const current = c.modResults.NSAppleMusicUsageDescription;
    const hasCurrent = typeof current === "string" && current.trim().length > 0;
    const hasOption =
      typeof musicUsageDescription === "string" &&
      musicUsageDescription.trim().length > 0;

    if (hasOption) {
      c.modResults.NSAppleMusicUsageDescription = musicUsageDescription;
    } else if (!hasCurrent) {
      c.modResults.NSAppleMusicUsageDescription = DEFAULT_MUSIC_USAGE;
    }

    return c;
  });
};

export default withExpoAppleMusic;
