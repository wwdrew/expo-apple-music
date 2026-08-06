# Library list/search on iOS stay REST for pagination parity

iOS `Library` **reads** (list songs/playlists/albums/artists/music-videos, library search) use Apple Music REST so `limit`/`offset` match Android and web. There is no parallel “native list” path that apps should prefer.

Native `MusicLibraryRequest` helpers on `LibraryService` exist only for **playback queue** resolution (`playLibrarySong` / `playLibraryPlaylist` / library-typed `setQueue`). Do not reintroduce native library list fetches for public read APIs without revisiting this decision — MusicKit library requests do not offer the same pagination contract.

See [PLATFORM_IMPLEMENTATION.md](../PLATFORM_IMPLEMENTATION.md) § Library, ADR-0001.
