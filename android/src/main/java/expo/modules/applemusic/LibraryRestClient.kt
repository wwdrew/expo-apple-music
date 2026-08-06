package expo.modules.applemusic

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject

/** Library-domain Apple Music REST (user collection reads + playback id resolution). */
internal class LibraryRestClient(
  private val transport: AppleMusicRestTransport,
) {
  suspend fun getLibraryPlaylists(musicUserToken: String, limit: Int, offset: Int): List<Map<String, Any?>> =
    withContext(Dispatchers.IO) {
      val json =
        transport.getJson(
          musicUserToken,
          "/v1/me/library/playlists",
          mapOf("limit" to limit.toString(), "offset" to offset.toString()),
        )
      mapTopLevelResourceArray(json) { AppleMusicJsonMapper.mapPlaylist(it) }
    }

  suspend fun getLibrarySongs(musicUserToken: String, limit: Int, offset: Int): List<Map<String, Any?>> =
    withContext(Dispatchers.IO) {
      val json =
        transport.getJson(
          musicUserToken,
          "/v1/me/library/songs",
          mapOf("limit" to limit.toString(), "offset" to offset.toString()),
        )
      mapTopLevelResourceArray(json) { AppleMusicJsonMapper.mapSong(it) }
    }

  suspend fun getPlaylistTracks(musicUserToken: String, playlistId: String): List<Map<String, Any?>> =
    withContext(Dispatchers.IO) {
      val json = transport.getJson(
          musicUserToken,
          "/v1/me/library/playlists/$playlistId/tracks")
      val data = requireDataArray(json)
      buildList {
        for (i in 0 until data.length()) {
          val resource = data.getJSONObject(i)
          if (resource.optString("type", "").contains("song")) {
            add(AppleMusicJsonMapper.mapSong(resource))
          }
        }
      }
    }

  private fun librarySearchTypeParam(type: String): String? =
    when (type) {
      "library-songs", "songs" -> "library-songs"
      "library-albums", "albums" -> "library-albums"
      "library-artists", "artists" -> "library-artists"
      "library-playlists", "playlists" -> "library-playlists"
      "library-music-videos", "music-videos", "musicVideos" -> "library-music-videos"
      else -> null
    }

  suspend fun getLibraryArtists(musicUserToken: String, limit: Int, offset: Int): List<Map<String, Any?>> =
    withContext(Dispatchers.IO) {
      val json =
        transport.getJson(
          musicUserToken,
          "/v1/me/library/artists",
          mapOf("limit" to limit.toString(), "offset" to offset.toString()),
        )
      mapTopLevelResourceArray(json) { AppleMusicJsonMapper.mapArtist(it) }
    }

  suspend fun getLibraryAlbums(musicUserToken: String, limit: Int, offset: Int): List<Map<String, Any?>> =
    withContext(Dispatchers.IO) {
      val json =
        transport.getJson(
          musicUserToken,
          "/v1/me/library/albums",
          mapOf("limit" to limit.toString(), "offset" to offset.toString()),
        )
      mapTopLevelResourceArray(json) { AppleMusicJsonMapper.mapAlbum(it) }
    }

  data class LibrarySearchResult(
    val songs: List<Map<String, Any?>>,
    val albums: List<Map<String, Any?>>,
    val artists: List<Map<String, Any?>>,
    val playlists: List<Map<String, Any?>>,
    val musicVideos: List<Map<String, Any?>>,
  )

  suspend fun getLibraryMusicVideos(musicUserToken: String, limit: Int, offset: Int): List<Map<String, Any?>> =
    withContext(Dispatchers.IO) {
      val json =
        transport.getJson(
          musicUserToken,
          "/v1/me/library/music-videos",
          mapOf("limit" to limit.toString(), "offset" to offset.toString()),
        )
      mapTopLevelResourceArray(json) { AppleMusicJsonMapper.mapMusicVideo(it) }
    }

  suspend fun searchLibrary(
    musicUserToken: String,
    term: String,
    types: List<String>,
    limit: Int,
    offset: Int,
  ): LibrarySearchResult =
    withContext(Dispatchers.IO) {
      val typeParam =
        types
          .mapNotNull { librarySearchTypeParam(it) }
          .distinct()
          .sorted()
          .joinToString(",")
          .ifEmpty { "library-songs,library-albums" }

      val json =
        transport.getJson(
          musicUserToken,
          "/v1/me/library/search",
          mapOf(
            "term" to term,
            "types" to typeParam,
            "limit" to limit.toString(),
            "offset" to offset.toString(),
          ),
        )

      val results = json.optJSONObject("results") ?: JSONObject()
      LibrarySearchResult(
        songs =
          mapResourceArray(results.optJSONObject("library-songs")?.optJSONArray("data")) {
            AppleMusicJsonMapper.mapSong(it)
          },
        albums =
          mapResourceArray(results.optJSONObject("library-albums")?.optJSONArray("data")) {
            AppleMusicJsonMapper.mapAlbum(it)
          },
        artists =
          mapResourceArray(results.optJSONObject("library-artists")?.optJSONArray("data")) {
            AppleMusicJsonMapper.mapArtist(it)
          },
        playlists =
          mapResourceArray(results.optJSONObject("library-playlists")?.optJSONArray("data")) {
            AppleMusicJsonMapper.mapPlaylist(it)
          },
        musicVideos =
          mapResourceArray(results.optJSONObject("library-music-videos")?.optJSONArray("data")) {
            AppleMusicJsonMapper.mapMusicVideo(it)
          },
      )
    }

  /**
   * Lightweight library probe for subscription inference.
   * Returns `false` only on HTTP 403 / `permissionDenied` (no library / subscription).
   * Network failures, missing tokens, and other API errors are rethrown.
   */
  suspend fun probeLibraryAccess(musicUserToken: String): Boolean =
    withContext(Dispatchers.IO) {
      try {
        transport.getJson(
          musicUserToken,
          "/v1/me/library/songs", mapOf("limit" to "1"))
        true
      } catch (error: expo.modules.kotlin.exception.CodedException) {
        if (
          error.code == AppleMusicErrorCodes.PERMISSION_DENIED &&
          error.message?.contains("403") == true
        ) {
          false
        } else {
          throw error
        }
      }
    }

  suspend fun resolveCatalogPlaybackId(musicUserToken: String, libraryId: String, mediaType: String): String =
    withContext(Dispatchers.IO) {
      val path =
        when (mediaType) {
          "song" -> "/v1/me/library/songs/$libraryId"
          "album" -> "/v1/me/library/albums/$libraryId"
          "playlist" -> "/v1/me/library/playlists/$libraryId"
          else -> throw AppleMusicErrors.unknownMediaType(mediaType)
        }
      val json = transport.getJson(musicUserToken, path)
      val resource = json.getJSONArray("data").getJSONObject(0)
      AppleMusicJsonMapper.catalogPlaybackId(resource)
        ?: throw AppleMusicErrors.itemNotFound(mediaType.replaceFirstChar { it.uppercase() }, true)
    }

  suspend fun resolveLibrarySongCatalogIds(musicUserToken: String, playlistId: String): List<String> =
    withContext(Dispatchers.IO) {
      val json = transport.getJson(
          musicUserToken,
          "/v1/me/library/playlists/$playlistId/tracks")
      val data = requireDataArray(json)
      buildList {
        for (i in 0 until data.length()) {
          val resource = data.getJSONObject(i)
          if (!resource.optString("type", "").contains("song")) continue
          AppleMusicJsonMapper.catalogPlaybackId(resource)?.let { add(it) }
        }
      }
    }
}
