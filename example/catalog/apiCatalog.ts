import {
  BRIDGE_METHODS,
  type BridgeDomain,
  type BridgeMethodSpec,
} from "../../src/bridge/bridge-methods";

export type ApiMethod = {
  id: string;
  name: string;
  signature: string;
  summary: string;
};

export type ApiModule = {
  id: string;
  name: string;
  description: string;
  methods: ApiMethod[];
};

type ModuleMeta = {
  id: string;
  name: string;
  description: string;
};

/** UI-only metadata keyed by bridge `publicName` (`Catalog.getSong`). */
type MethodUi = {
  signature: string;
  summary: string;
};

const DOMAIN_META: Record<BridgeDomain, ModuleMeta> = {
  auth: {
    id: "auth",
    name: "Auth",
    description: "Authorization, subscription checks, and storefront.",
  },
  catalog: {
    id: "catalog",
    name: "Catalog",
    description: "Search and browse the Apple Music catalog.",
  },
  player: {
    id: "player",
    name: "Player",
    description: "Playback queue, transport controls, and events.",
  },
  library: {
    id: "library",
    name: "Library",
    description: "Read the user's Apple Music library.",
  },
  history: {
    id: "history",
    name: "History",
    description: "Recently played, heavy rotation, and recently added.",
  },
  libraryMutations: {
    id: "library-mutations",
    name: "LibraryMutations",
    description: "Add to library and manage playlists.",
  },
  ratings: {
    id: "ratings",
    name: "Ratings",
    description: "Like, dislike, and favorites.",
  },
  recommendations: {
    id: "recommendations",
    name: "Recommendations",
    description: "Personalized recommendations and Replay.",
  },
};

const METHOD_UI: Record<string, MethodUi> = {
  "Auth.authorize": {
    signature: "Auth.authorize(developerToken?, options?)",
    summary: "Request Apple Music access. Android/web require a developer JWT.",
  },
  "Auth.setDeveloperToken": {
    signature: "Auth.setDeveloperToken(developerToken)",
    summary: "Store developer JWT on native/web without re-running user sign-in.",
  },
  "Auth.checkSubscription": {
    signature: "Auth.checkSubscription(musicUserToken)",
    summary: "Check whether the user can play catalog content.",
  },
  "Auth.getStorefront": {
    signature: "Auth.getStorefront(musicUserToken)",
    summary: "User storefront country code (e.g. us).",
  },
  "Catalog.search": {
    signature: "Catalog.search(term, types, options?)",
    summary: "Search songs, albums, artists, playlists, and more.",
  },
  "Catalog.getSong": {
    signature: "Catalog.getSong(id)",
    summary: "Fetch a catalog song by ID.",
  },
  "Catalog.getAlbum": {
    signature: "Catalog.getAlbum(id)",
    summary: "Fetch a catalog album by ID.",
  },
  "Catalog.getArtist": {
    signature: "Catalog.getArtist(id)",
    summary: "Fetch a catalog artist by ID.",
  },
  "Catalog.getPlaylist": {
    signature: "Catalog.getPlaylist(id)",
    summary: "Fetch a catalog playlist by ID.",
  },
  "Catalog.getStation": {
    signature: "Catalog.getStation(id)",
    summary: "Fetch a catalog station by ID.",
  },
  "Catalog.getMusicVideo": {
    signature: "Catalog.getMusicVideo(id)",
    summary: "Fetch a catalog music video by ID.",
  },
  "Catalog.getAlbumTracks": {
    signature: "Catalog.getAlbumTracks(albumId, options?)",
    summary: "Tracks on a catalog album.",
  },
  "Catalog.getArtistAlbums": {
    signature: "Catalog.getArtistAlbums(artistId, options?)",
    summary: "Albums by a catalog artist.",
  },
  "Catalog.getPlaylistTracks": {
    signature: "Catalog.getPlaylistTracks(playlistId, options?)",
    summary: "Tracks in a catalog playlist.",
  },
  "Catalog.getCharts": {
    signature: "Catalog.getCharts(types, options?)",
    summary: "Top charts for songs, albums, and other types.",
  },
  "Catalog.getByIds": {
    signature: "Catalog.getByIds(type, ids)",
    summary: "Fetch multiple catalog resources by storefront id.",
  },
  "Player.configurePlayer": {
    signature: "Player.configurePlayer(options?)",
    summary:
      "Configure playback (default: application). Prefer { mixWithOthers } or { player }. See docs/PLAYBACK.md.",
  },
  "Player.setQueue": {
    signature: "Player.setQueue(itemId, type)",
    summary: "Queue a catalog song, album, playlist, or station.",
  },
  "Player.playLibrarySong": {
    signature: "Player.playLibrarySong(musicUserToken, songId)",
    summary: "Play a song from the user's library.",
  },
  "Player.playLibraryPlaylist": {
    signature: "Player.playLibraryPlaylist(musicUserToken, playlistId, startingAt?)",
    summary: "Play a library playlist.",
  },
  "Player.getCurrentState": {
    signature: "Player.getCurrentState()",
    summary: "Current playback status and position.",
  },
  "Player.play": {
    signature: "Player.play()",
    summary: "Resume playback.",
  },
  "Player.pause": {
    signature: "Player.pause()",
    summary: "Pause playback.",
  },
  "Player.togglePlayerState": {
    signature: "Player.togglePlayerState()",
    summary: "Toggle play/pause.",
  },
  "Player.skipToNextEntry": {
    signature: "Player.skipToNextEntry()",
    summary: "Skip to the next queue item.",
  },
  "Player.skipToPreviousEntry": {
    signature: "Player.skipToPreviousEntry()",
    summary: "Skip to the previous queue item.",
  },
  "Player.restartCurrentEntry": {
    signature: "Player.restartCurrentEntry()",
    summary: "Restart the current track from the beginning.",
  },
  "Player.seekToTime": {
    signature: "Player.seekToTime(seconds)",
    summary: "Seek within the current track (also in the player bar).",
  },
  "Library.getPlaylists": {
    signature: "Library.getPlaylists(musicUserToken, options?)",
    summary: "User-created and added playlists.",
  },
  "Library.getSongs": {
    signature: "Library.getSongs(musicUserToken, options?)",
    summary: "Songs in the user's library.",
  },
  "Library.getPlaylistTracks": {
    signature: "Library.getPlaylistTracks(musicUserToken, playlistId, options?)",
    summary: "Tracks in a library playlist.",
  },
  "Library.getArtists": {
    signature: "Library.getArtists(musicUserToken, options?)",
    summary: "Artists in the user's library.",
  },
  "Library.getAlbums": {
    signature: "Library.getAlbums(musicUserToken, options?)",
    summary: "Albums in the user's library.",
  },
  "Library.getMusicVideos": {
    signature: "Library.getMusicVideos(musicUserToken, options?)",
    summary: "Music videos in the user's library.",
  },
  "Library.search": {
    signature: "Library.search(musicUserToken, term, types, options?)",
    summary: "Search the user's library (not the catalog store).",
  },
  "History.getRecentlyPlayedResources": {
    signature: "History.getRecentlyPlayedResources(musicUserToken)",
    summary: "Recently played albums, playlists, and stations.",
  },
  "History.getRecentlyPlayedTracks": {
    signature: "History.getRecentlyPlayedTracks(musicUserToken, options?)",
    summary: "Recently played songs.",
  },
  "History.getHeavyRotation": {
    signature: "History.getHeavyRotation(musicUserToken, options?)",
    summary: "Resources the user plays most often.",
  },
  "History.getRecentlyPlayedStations": {
    signature: "History.getRecentlyPlayedStations(musicUserToken, options?)",
    summary: "Recently played radio stations.",
  },
  "History.getRecentlyAdded": {
    signature: "History.getRecentlyAdded(musicUserToken, options?)",
    summary: "Albums and playlists recently added to the library.",
  },
  "LibraryMutations.addToLibrary": {
    signature: "LibraryMutations.addToLibrary(musicUserToken, resourceIds)",
    summary: "Add catalog resources to the user's library.",
  },
  "LibraryMutations.createPlaylist": {
    signature: "LibraryMutations.createPlaylist(musicUserToken, options)",
    summary: "Create a new library playlist.",
  },
  "LibraryMutations.addTracksToPlaylist": {
    signature: "LibraryMutations.addTracksToPlaylist(musicUserToken, playlistId, tracks)",
    summary: "Add tracks to an existing library playlist.",
  },
  "Ratings.getRating": {
    signature: "Ratings.getRating(musicUserToken, resourceType, id)",
    summary: "Get the user's rating for a resource.",
  },
  "Ratings.setRating": {
    signature: "Ratings.setRating(musicUserToken, resourceType, id, value)",
    summary: "Set like or dislike on a resource.",
  },
  "Ratings.clearRating": {
    signature: "Ratings.clearRating(musicUserToken, resourceType, id)",
    summary: "Remove a rating.",
  },
  "Ratings.addToFavorites": {
    signature: "Ratings.addToFavorites(musicUserToken, resourceIds)",
    summary: "Add resources to favorites.",
  },
  "Ratings.removeFromFavorites": {
    signature: "Ratings.removeFromFavorites(musicUserToken, resourceIds)",
    summary: "Remove resources from favorites.",
  },
  "Recommendations.get": {
    signature: "Recommendations.get(musicUserToken, ids?)",
    summary: "Personalized recommendation groups (Made for You, etc.).",
  },
  "Recommendations.getReplay": {
    signature: "Recommendations.getReplay(musicUserToken, year?)",
    summary: "Apple Music Replay summaries for a year.",
  },
};

/** Playground-only entries that are not Expo AsyncFunctions. */
const PLAYER_EXTRA_METHODS: ApiMethod[] = [
  {
    id: "addListener",
    name: "addListener",
    signature: "Player.addListener(event, listener)",
    summary: "Subscribe to playback state, song, time, and error events.",
  },
];

const HOOKS_MODULE: ApiModule = {
  id: "hooks",
  name: "Hooks",
  description: "React hooks for playback UI (used in the player bar).",
  methods: [
    {
      id: "useCurrentSong",
      name: "useCurrentSong",
      signature: "useCurrentSong()",
      summary: "Currently playing song metadata.",
    },
    {
      id: "useIsPlaying",
      name: "useIsPlaying",
      signature: "useIsPlaying()",
      summary: "Whether playback is active.",
    },
    {
      id: "usePlaybackState",
      name: "usePlaybackState",
      signature: "usePlaybackState()",
      summary: "Playback status, position, and duration.",
    },
  ],
};

const DOMAIN_ORDER: BridgeDomain[] = [
  "auth",
  "catalog",
  "player",
  "library",
  "history",
  "libraryMutations",
  "ratings",
  "recommendations",
];

function methodIdFromPublicName(publicName: string): string {
  const method = publicName.split(".").pop();
  if (!method) {
    throw new Error(`Invalid bridge publicName: ${publicName}`);
  }
  return method;
}

function toApiMethod(spec: BridgeMethodSpec): ApiMethod {
  const ui = METHOD_UI[spec.publicName];
  if (!ui) {
    throw new Error(
      `Missing playground UI metadata for ${spec.publicName}. Add an entry to METHOD_UI in example/catalog/apiCatalog.ts.`,
    );
  }
  const id = methodIdFromPublicName(spec.publicName);
  return {
    id,
    name: id,
    signature: ui.signature,
    summary: ui.summary,
  };
}

function buildBridgeModules(): ApiModule[] {
  return DOMAIN_ORDER.map((domain) => {
    const meta = DOMAIN_META[domain];
    const methods = BRIDGE_METHODS.filter((m) => m.domain === domain).map(toApiMethod);
    if (domain === "player") {
      return { ...meta, methods: [...methods, ...PLAYER_EXTRA_METHODS] };
    }
    return { ...meta, methods };
  });
}

/** Playground catalog: method *lists* come from `BRIDGE_METHODS`; prose/UI stays local. */
export const API_MODULES: ApiModule[] = [...buildBridgeModules(), HOOKS_MODULE];

export function getModule(moduleId: string): ApiModule | undefined {
  return API_MODULES.find((m) => m.id === moduleId);
}

export function getMethod(
  moduleId: string,
  methodId: string,
): ApiMethod | undefined {
  return getModule(moduleId)?.methods.find((m) => m.id === methodId);
}
