import fs from "fs";
import path from "path";

/** Filenames must match `expo-module.config.json` → `gradleAarProjects`. */
export const ANDROID_MUSICKIT_AAR_FILES = [
  "musickitauth-release-1.1.2.aar",
  "mediaplayback-release-1.1.1.aar",
] as const;

export type AndroidMusicKitAarFile = (typeof ANDROID_MUSICKIT_AAR_FILES)[number];

export function getModuleAndroidLibsDir(moduleRoot: string): string {
  return path.join(moduleRoot, "android", "libs");
}

export class MissingAndroidMusicKitAarsError extends Error {
  constructor(
    public readonly sourceDir: string,
    public readonly missingFiles: readonly string[],
  ) {
    super(formatMissingAndroidMusicKitAarsMessage(sourceDir, missingFiles));
    this.name = "MissingAndroidMusicKitAarsError";
  }
}

export function formatMissingAndroidMusicKitAarsMessage(
  sourceDir: string,
  missingFiles: readonly string[],
): string {
  const fileList = missingFiles.map((file) => `  - ${file}`).join("\n");
  return (
    `[expo-apple-music] Missing Apple MusicKit Android AAR file(s) in ${sourceDir}:\n` +
    `${fileList}\n\n` +
    "Download the MusicKit SDK for Android from https://developer.apple.com/musickit/ " +
    "(Apple Developer account required), place both .aar files in the directory " +
    "configured as `androidMusicKitAarDir`, then run `npx expo prebuild` again."
  );
}

export function copyAndroidMusicKitAars(options: {
  sourceDir: string;
  moduleRoot: string;
}): void {
  const { sourceDir, moduleRoot } = options;
  const targetDir = getModuleAndroidLibsDir(moduleRoot);

  if (!fs.existsSync(sourceDir)) {
    throw new MissingAndroidMusicKitAarsError(
      sourceDir,
      [...ANDROID_MUSICKIT_AAR_FILES],
    );
  }

  fs.mkdirSync(targetDir, { recursive: true });

  const missingFiles: string[] = [];
  for (const fileName of ANDROID_MUSICKIT_AAR_FILES) {
    const sourcePath = path.join(sourceDir, fileName);
    if (!fs.existsSync(sourcePath)) {
      missingFiles.push(fileName);
      continue;
    }
    fs.copyFileSync(sourcePath, path.join(targetDir, fileName));
  }

  if (missingFiles.length > 0) {
    throw new MissingAndroidMusicKitAarsError(sourceDir, missingFiles);
  }
}
