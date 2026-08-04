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

export const API_MODULES: ApiModule[] = [
  {
    id: "auth",
    name: "Auth",
    description: "Authorization, subscription checks, and storefront.",
    methods: [
      {
        id: "authorize",
        name: "authorize",
        signature: "Auth.authorize(developerToken?, options?)",
        summary: "Request Apple Music access. Android/web require a developer JWT.",
      },
      {
        id: "setDeveloperToken",
        name: "setDeveloperToken",
        signature: "Auth.setDeveloperToken(developerToken)",
        summary: "Store developer JWT on native/web without re-running user sign-in.",
      },
      {
        id: "checkSubscription",
        name: "checkSubscription",
        signature: "Auth.checkSubscription(musicUserToken)",
        summary: "Check whether the user can play catalog content.",
      },
      {
        id: "getStorefront",
        name: "getStorefront",
        signature: "Auth.getStorefront(musicUserToken)",
        summary: "User storefront country code (e.g. us).",
      },
    ],
  },
  {
    id: "catalog",
    name: "Catalog",
    description: "Search and browse the Apple Music catalog.",
    methods: [
      {
        id: "search",
        name: "search",
        signature:
          "Catalog.search(term, types, options?)",
        summary: "Search songs, albums, artists, playlists, and more.",
      },
      {
        id: "getSong",
        name: "getSong",
        signature: "Catalog.getSong(id)",
        summary: "Fetch a catalog song by ID.",
      },
      {
        id: "getAlbum",
        name: "getAlbum",
        signature: "Catalog.getAlbum(id)",
        summary: "Fetch a catalog album by ID.",
      },
      {
        id: "getArtist",
        name: "getArtist",
        signature: "Catalog.getArtist(id)",
        summary: "Fetch a catalog artist by ID.",
      },
      {
        id: "getPlaylist",
        name: "getPlaylist",
        signature: "Catalog.getPlaylist(id)",
        summary: "Fetch a catalog playlist by ID.",
      },
      {
        id: "getStation",
        name: "getStation",
        signature: "Catalog.getStation(id)",
        summary: "Fetch a catalog station by ID.",
      },
      {
        id: "getMusicVideo",
        name: "getMusicVideo",
        signature: "Catalog.getMusicVideo(id)",
        summary: "Fetch a catalog music video by ID.",
      },
      {
        id: "getAlbumTracks",
        name: "getAlbumTracks",
        signature: "Catalog.getAlbumTracks(albumId, options?)",
        summary: "Tracks on a catalog album.",
      },
      {
        id: "getArtistAlbums",
        name: "getArtistAlbums",
        signature: "Catalog.getArtistAlbums(artistId, options?)",
        summary: "Albums by a catalog artist.",
      },
      {
        id: "getPlaylistTracks",
        name: "getPlaylistTracks",
        signature: "Catalog.getPlaylistTracks(playlistId, options?)",
        summary: "Tracks in a catalog playlist.",
      },
      {
        id: "getCharts",
        name: "getCharts",
        signature: "Catalog.getCharts(types, options?)",
        summary: "Top charts for songs, albums, and other types.",
      },
      {
        id: "getByIds",
        name: "getByIds",
        signature: "Catalog.getByIds(type, ids)",
        summary: "Fetch multiple catalog resources by storefront id.",
      },
    ],
  },
  {
    id: "player",
    name: "Player",
    description: "Playback queue, transport controls, and events.",
    methods: [
      {
        id: "configurePlayer",
        name: "configurePlayer",
        signature: "Player.configurePlayer(options?)",
        summary: "Configure the audio session before playback.",
      },
      {
        id: "setQueue",
        name: "setQueue",
        signature: "Player.setQueue(itemId, type)",
        summary: "Queue a catalog song, album, playlist, or station.",
      },
      {
        id: "playLibrarySong",
        name: "playLibrarySong",
        signature: "Player.playLibrarySong(musicUserToken, songId)",
        summary: "Play a song from the user's library.",
      },
      {
        id: "playLibraryPlaylist",
        name: "playLibraryPlaylist",
        signature: "Player.playLibraryPlaylist(musicUserToken, playlistId, startingAt?)",
        summary: "Play a library playlist.",
      },
      {
        id: "getCurrentState",
        name: "getCurrentState",
        signature: "Player.getCurrentState()",
        summary: "Current playback status and position.",
      },
      {
        id: "play",
        name: "play",
        signature: "Player.play()",
        summary: "Resume playback.",
      },
      {
        id: "pause",
        name: "pause",
        signature: "Player.pause()",
        summary: "Pause playback.",
      },
      {
        id: "togglePlayerState",
        name: "togglePlayerState",
        signature: "Player.togglePlayerState()",
        summary: "Toggle play/pause.",
      },
      {
        id: "skipToNextEntry",
        name: "skipToNextEntry",
        signature: "Player.skipToNextEntry()",
        summary: "Skip to the next queue item.",
      },
      {
        id: "skipToPreviousEntry",
        name: "skipToPreviousEntry",
        signature: "Player.skipToPreviousEntry()",
        summary: "Skip to the previous queue item.",
      },
      {
        id: "restartCurrentEntry",
        name: "restartCurrentEntry",
        signature: "Player.restartCurrentEntry()",
        summary: "Restart the current track from the beginning.",
      },
      {
        id: "seekToTime",
        name: "seekToTime",
        signature: "Player.seekToTime(seconds)",
        summary: "Seek within the current track (also in the player bar).",
      },
      {
        id: "addListener",
        name: "addListener",
        signature: "Player.addListener(event, listener)",
        summary: "Subscribe to playback state, song, time, and error events.",
      },
    ],
  },
  {
    id: "library",
    name: "Library",
    description: "Read the user's Apple Music library.",
    methods: [
      {
        id: "getPlaylists",
        name: "getPlaylists",
        signature: "Library.getPlaylists(musicUserToken, options?)",
        summary: "User-created and added playlists.",
      },
      {
        id: "getSongs",
        name: "getSongs",
        signature: "Library.getSongs(musicUserToken, options?)",
        summary: "Songs in the user's library.",
      },
      {
        id: "getPlaylistTracks",
        name: "getPlaylistTracks",
        signature: "Library.getPlaylistTracks(musicUserToken, playlistId, options?)",
        summary: "Tracks in a library playlist.",
      },
      {
        id: "getArtists",
        name: "getArtists",
        signature: "Library.getArtists(musicUserToken, options?)",
        summary: "Artists in the user's library.",
      },
      {
        id: "getAlbums",
        name: "getAlbums",
        signature: "Library.getAlbums(musicUserToken, options?)",
        summary: "Albums in the user's library.",
      },
      {
        id: "getMusicVideos",
        name: "getMusicVideos",
        signature: "Library.getMusicVideos(musicUserToken, options?)",
        summary: "Music videos in the user's library.",
      },
      {
        id: "search",
        name: "search",
        signature: "Library.search(musicUserToken, term, types, options?)",
        summary: "Search the user's library (not the catalog store).",
      },
    ],
  },
  {
    id: "history",
    name: "History",
    description: "Recently played, heavy rotation, and recently added.",
    methods: [
      {
        id: "getRecentlyPlayedResources",
        name: "getRecentlyPlayedResources",
        signature: "History.getRecentlyPlayedResources(musicUserToken)",
        summary: "Recently played albums, playlists, and stations.",
      },
      {
        id: "getRecentlyPlayedTracks",
        name: "getRecentlyPlayedTracks",
        signature: "History.getRecentlyPlayedTracks(musicUserToken, options?)",
        summary: "Recently played songs.",
      },
      {
        id: "getHeavyRotation",
        name: "getHeavyRotation",
        signature: "History.getHeavyRotation(musicUserToken, options?)",
        summary: "Resources the user plays most often.",
      },
      {
        id: "getRecentlyPlayedStations",
        name: "getRecentlyPlayedStations",
        signature: "History.getRecentlyPlayedStations(musicUserToken, options?)",
        summary: "Recently played radio stations.",
      },
      {
        id: "getRecentlyAdded",
        name: "getRecentlyAdded",
        signature: "History.getRecentlyAdded(musicUserToken, options?)",
        summary: "Albums and playlists recently added to the library.",
      },
    ],
  },
  {
    id: "library-mutations",
    name: "LibraryMutations",
    description: "Add to library and manage playlists.",
    methods: [
      {
        id: "addToLibrary",
        name: "addToLibrary",
        signature: "LibraryMutations.addToLibrary(musicUserToken, resourceIds)",
        summary: "Add catalog resources to the user's library.",
      },
      {
        id: "createPlaylist",
        name: "createPlaylist",
        signature: "LibraryMutations.createPlaylist(musicUserToken, options)",
        summary: "Create a new library playlist.",
      },
      {
        id: "addTracksToPlaylist",
        name: "addTracksToPlaylist",
        signature:
          "LibraryMutations.addTracksToPlaylist(musicUserToken, playlistId, tracks)",
        summary: "Add tracks to an existing library playlist.",
      },
    ],
  },
  {
    id: "ratings",
    name: "Ratings",
    description: "Like, dislike, and favorites.",
    methods: [
      {
        id: "getRating",
        name: "getRating",
        signature: "Ratings.getRating(musicUserToken, resourceType, id)",
        summary: "Get the user's rating for a resource.",
      },
      {
        id: "setRating",
        name: "setRating",
        signature: "Ratings.setRating(musicUserToken, resourceType, id, value)",
        summary: "Set like or dislike on a resource.",
      },
      {
        id: "clearRating",
        name: "clearRating",
        signature: "Ratings.clearRating(musicUserToken, resourceType, id)",
        summary: "Remove a rating.",
      },
      {
        id: "addToFavorites",
        name: "addToFavorites",
        signature: "Ratings.addToFavorites(musicUserToken, resourceIds)",
        summary: "Add resources to favorites.",
      },
      {
        id: "removeFromFavorites",
        name: "removeFromFavorites",
        signature: "Ratings.removeFromFavorites(musicUserToken, resourceIds)",
        summary: "Remove resources from favorites.",
      },
    ],
  },
  {
    id: "recommendations",
    name: "Recommendations",
    description: "Personalized recommendations and Replay.",
    methods: [
      {
        id: "get",
        name: "get",
        signature: "Recommendations.get(musicUserToken, ids?)",
        summary: "Personalized recommendation groups (Made for You, etc.).",
      },
      {
        id: "getReplay",
        name: "getReplay",
        signature: "Recommendations.getReplay(musicUserToken, year?)",
        summary: "Apple Music Replay summaries for a year.",
      },
    ],
  },
  {
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
  },
];

export function getModule(moduleId: string): ApiModule | undefined {
  return API_MODULES.find((m) => m.id === moduleId);
}

export function getMethod(
  moduleId: string,
  methodId: string,
): ApiMethod | undefined {
  return getModule(moduleId)?.methods.find((m) => m.id === methodId);
}
