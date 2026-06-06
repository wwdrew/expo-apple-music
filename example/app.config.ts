import type { ExpoConfig } from "expo/config";
import buildProperties from "expo-build-properties/plugin";
import expoAppleMusic from "@wwdrew/expo-apple-music/plugin";
import splashScreen from "expo-splash-screen/plugin";

const config: ExpoConfig = {
  name: "expo-apple-music-example",
  slug: "expo-apple-music-example",
  version: "1.0.0",
  orientation: "portrait",
  icon: "./assets/icon.png",
  userInterfaceStyle: "light",
  plugins: [
    expoAppleMusic({
      musicUsageDescription:
        "This example app uses Apple Music for testing MusicKit.",
      androidMusicKitAarDir: "./vendor/apple-musickit-android",
    }),
    buildProperties({
      ios: {
        deploymentTarget: "16.4",
      },
      android: {
        // SDK 56: experimental faster Android codegen builds (see Expo SDK 56 changelog).
        usePrecompiledHeaders: true,
      },
    }),
    splashScreen({
      image: "./assets/splash-icon.png",
      resizeMode: "contain",
      backgroundColor: "#ffffff",
    }),
    "expo-router",
  ],
  ios: {
    supportsTablet: true,
    bundleIdentifier: "com.wwdrew.applemusic.example",
  },
  android: {
    adaptiveIcon: {
      foregroundImage: "./assets/adaptive-icon.png",
      backgroundColor: "#ffffff",
    },
    predictiveBackGestureEnabled: false,
    package: "com.wwdrew.applemusic.example",
  },
  scheme: "expo-apple-music-example",
  web: {
    favicon: "./assets/favicon.png",
  },
};

export default config;
