import { MusicItem, Player, type ConfigurePlayerOptions } from "@wwdrew/expo-apple-music";
import { formatApiError } from "../lib/format-error";
import { requireMusicToken } from "../lib/require-music-token";
import { useEffect, useState } from "react";
import { Text } from "react-native";
import { ApiScreen } from "../components/ApiScreen";
import { IdField } from "../components/IdField";
import { useApp } from "../context/AppContext";
import { playCatalogSong } from "./catalog";
import { RunButton } from "./helpers";

export function ConfigurePlayerDemo() {
  const { appendLog } = useApp();

  const run = (label: string, options: boolean | ConfigurePlayerOptions = false) => {
    void Player.configurePlayer(options)
      .then((c) =>
        appendLog(
          `${label} → playerType=${c.playerType}, mixWithOthers=${c.mixWithOthers}, session=${JSON.stringify(c.audioSession)}`,
        ),
      )
      .catch((e) => appendLog(`error: ${formatApiError(e)}`));
  };

  return (
    <ApiScreen
      hint="Default backend is application (in-app). Prefer player (alias of playerType). system is iOS Music app / system playback. Android/web only echo the payload."
      actions={
        <>
          <RunButton title="Defaults (application, exclusive)" onPress={() => run("defaults", {})} />
          <RunButton title="mixWithOthers: true" onPress={() => run("mix", { mixWithOthers: true })} />
          <RunButton title="player: system" onPress={() => run("system", { player: "system" })} />
          <RunButton
            title="player: application"
            onPress={() => run("application", { player: "application" })}
          />
          <RunButton
            title="Legacy playerType: system"
            onPress={() => run("legacy-playerType", { playerType: "system" })}
          />
          <RunButton title="Legacy boolean false" onPress={() => run("legacy-false", false)} />
        </>
      }
    />
  );
}

export function SetQueueDemo() {
  const { appendLog, catalogSongs, catalogAlbums, setSelectedSongId } = useApp();
  const [songId, setSongId] = useState(catalogSongs[0]?.id ?? "");
  const [albumId, setAlbumId] = useState(catalogAlbums[0]?.id ?? "");
  useEffect(() => {
    if (!songId && catalogSongs[0]?.id) setSongId(catalogSongs[0].id);
  }, [catalogSongs, songId]);
  useEffect(() => {
    if (!albumId && catalogAlbums[0]?.id) setAlbumId(catalogAlbums[0].id);
  }, [albumId, catalogAlbums]);

  return (
    <ApiScreen
      hint="Catalog ids only. Station queues work on iOS/web; Android permanently rejects them (UNSUPPORTED_PLATFORM). Call Player.play() after queueing unless you use Queue + play."
      headerExtra={
        <>
          <IdField label="Song id" value={songId} onChangeText={setSongId} />
          <IdField label="Album id" value={albumId} onChangeText={setAlbumId} />
        </>
      }
      actions={
        <>
          <RunButton
            title="Queue song (no auto-play)"
            disabled={!songId.trim()}
            onPress={() => {
              setSelectedSongId(songId.trim());
              void Player.configurePlayer(false)
                .then(() => Player.setQueue(songId.trim(), MusicItem.SONG))
                .then(() => Player.getCurrentState())
                .then((state) => appendLog(`queue song — status: ${state.playbackStatus}`))
                .catch((e) => appendLog(`error: ${formatApiError(e)}`));
            }}
          />
          <RunButton
            title="Queue album (no auto-play)"
            disabled={!albumId.trim()}
            onPress={() => {
              void Player.configurePlayer(false)
                .then(() => Player.setQueue(albumId.trim(), MusicItem.ALBUM))
                .then(() => Player.getCurrentState())
                .then((state) => appendLog(`queue album — status: ${state.playbackStatus}`))
                .catch((e) => appendLog(`error: ${formatApiError(e)}`));
            }}
          />
          <RunButton
            title="Queue + play song"
            disabled={!songId.trim()}
            onPress={() => {
              setSelectedSongId(songId.trim());
              void playCatalogSong(songId.trim(), appendLog).catch((e) =>
                appendLog(`error: ${formatApiError(e)}`),
              );
            }}
          />
        </>
      }
    />
  );
}

export function PlayLibrarySongDemo() {
  const { musicUserToken, appendLog } = useApp();
  const [songId, setSongId] = useState("");
  return (
    <ApiScreen
      hint="Requires a library song id (i.* prefix), not a catalog id."
      headerExtra={
        <IdField label="Library song id" value={songId} onChangeText={setSongId} />
      }
      actions={
        <RunButton
          title="Run playLibrarySong(songId)"
          disabled={!songId.trim()}
          onPress={() => {
            if (!requireMusicToken(musicUserToken, appendLog)) return;
            void Player.playLibrarySong(musicUserToken, songId.trim())
              .then(() => appendLog(`playing library song ${songId.trim()}`))
              .catch((e) => appendLog(`error: ${formatApiError(e)}`));
          }}
        />
      }
    />
  );
}

export function PlayLibraryPlaylistDemo() {
  const { musicUserToken, appendLog, lastPlaylistId } = useApp();
  const [playlistId, setPlaylistId] = useState(lastPlaylistId ?? "");
  useEffect(() => {
    if (!playlistId && lastPlaylistId) setPlaylistId(lastPlaylistId);
  }, [lastPlaylistId, playlistId]);

  return (
    <ApiScreen
      headerExtra={
        <IdField
          label="Library playlist id"
          value={playlistId}
          onChangeText={setPlaylistId}
          hint="Run Library.getPlaylists and tap a playlist, or paste an id."
        />
      }
      actions={
        <RunButton
          title="Run playLibraryPlaylist(playlistId)"
          disabled={!playlistId.trim()}
          onPress={() => {
            if (!requireMusicToken(musicUserToken, appendLog)) return;
            void Player.playLibraryPlaylist(musicUserToken, playlistId.trim())
              .then(() => appendLog(`playing playlist ${playlistId.trim()}`))
              .catch((e) => appendLog(`error: ${formatApiError(e)}`));
          }}
        />
      }
    />
  );
}

export function GetCurrentStateDemo() {
  const { appendLog } = useApp();
  return (
    <ApiScreen
      actions={
        <RunButton
          title="Run getCurrentState()"
          onPress={() => {
            void Player.getCurrentState()
              .then((s) =>
                appendLog(
                  `status: ${s.playbackStatus}, time: ${s.playbackTime.toFixed(1)}s`,
                ),
              )
              .catch((e) => appendLog(`error: ${formatApiError(e)}`));
          }}
        />
      }
    />
  );
}

export function PlayDemo() {
  const { appendLog } = useApp();
  return (
    <ApiScreen
      hint="Queue something first. Transport controls also live in the player bar."
      actions={
        <RunButton
          title="Run play()"
          onPress={() => {
            try {
              Player.play();
              appendLog("play() called");
            } catch (e) {
              appendLog(`error: ${formatApiError(e)}`);
            }
          }}
        />
      }
    />
  );
}

export function PauseDemo() {
  const { appendLog } = useApp();
  return (
    <ApiScreen
      actions={
        <RunButton
          title="Run pause()"
          onPress={() => {
            try {
              Player.pause();
              appendLog("pause() called");
            } catch (e) {
              appendLog(`error: ${formatApiError(e)}`);
            }
          }}
        />
      }
    />
  );
}

export function TogglePlayerStateDemo() {
  const { appendLog } = useApp();
  return (
    <ApiScreen
      actions={
        <RunButton
          title="Run togglePlayerState()"
          onPress={() => {
            try {
              Player.togglePlayerState();
              appendLog("togglePlayerState() called");
            } catch (e) {
              appendLog(`error: ${formatApiError(e)}`);
            }
          }}
        />
      }
    />
  );
}

export function SkipToNextEntryDemo() {
  const { appendLog } = useApp();
  return (
    <ApiScreen
      actions={
        <RunButton
          title="Run skipToNextEntry()"
          onPress={() => {
            try {
              Player.skipToNextEntry();
              appendLog("skipToNextEntry() called");
            } catch (e) {
              appendLog(`error: ${formatApiError(e)}`);
            }
          }}
        />
      }
    />
  );
}

export function SkipToPreviousEntryDemo() {
  const { appendLog } = useApp();
  return (
    <ApiScreen
      actions={
        <RunButton
          title="Run skipToPreviousEntry()"
          onPress={() => {
            try {
              Player.skipToPreviousEntry();
              appendLog("skipToPreviousEntry() called");
            } catch (e) {
              appendLog(`error: ${formatApiError(e)}`);
            }
          }}
        />
      }
    />
  );
}

export function RestartCurrentEntryDemo() {
  const { appendLog } = useApp();
  return (
    <ApiScreen
      actions={
        <RunButton
          title="Run restartCurrentEntry()"
          onPress={() => {
            try {
              Player.restartCurrentEntry();
              appendLog("restartCurrentEntry() called");
            } catch (e) {
              appendLog(`error: ${formatApiError(e)}`);
            }
          }}
        />
      }
    />
  );
}

export function SeekToTimeDemo() {
  const { appendLog } = useApp();
  return (
    <ApiScreen
      hint="Also demonstrated via the scrubber in the player bar."
      actions={
        <RunButton
          title="Seek to 30s"
          onPress={() => {
            try {
              Player.seekToTime(30);
              appendLog("seekToTime(30) called");
            } catch (e) {
              appendLog(`error: ${formatApiError(e)}`);
            }
          }}
        />
      }
    />
  );
}

export function AddListenerDemo() {
  const { appendLog } = useApp();
  useEffect(() => {
    const subs = [
      Player.addListener("onPlaybackStateChange", (state) => {
        appendLog(`event onPlaybackStateChange: ${state.playbackStatus}`);
      }),
      Player.addListener("onCurrentSongChange", (event) => {
        appendLog(`event onCurrentSongChange: ${event.currentSong?.title ?? "(none)"}`);
      }),
    ];
    appendLog("Listening for onPlaybackStateChange and onCurrentSongChange");
    return () => subs.forEach((s) => s.remove());
  }, [appendLog]);

  return (
    <ApiScreen
      hint="Events append to the log when playback changes. Queue a song to see updates."
      headerExtra={
        <Text style={{ fontSize: 13, color: "#666" }}>
          This screen registers listeners on mount. Global onPlaybackError is
          registered in AppProvider.
        </Text>
      }
    />
  );
}
