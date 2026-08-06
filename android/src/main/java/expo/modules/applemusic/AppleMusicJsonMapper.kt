package expo.modules.applemusic

import org.json.JSONObject

/**
 * Maps Apple Music API JSON resources to bridge dictionaries matching [ios/MusicItemMapper.swift].
 */
internal object AppleMusicJsonMapper {
  fun mapSong(resource: JSONObject): Map<String, Any?> {
    val attributes = resource.optJSONObject("attributes") ?: JSONObject()
    val id = catalogPlaybackId(resource) ?: resource.optString("id", "")
    return mapOf(
      "id" to id,
      "title" to attributes.optString("name", ""),
      "artistName" to attributes.optString("artistName", ""),
      "artworkUrl" to artworkUrl(attributes.optJSONObject("artwork")),
      "duration" to durationMillis(attributes),
    )
  }

  fun mapAlbum(resource: JSONObject): Map<String, Any?> {
    val attributes = resource.optJSONObject("attributes") ?: JSONObject()
    return mapOf(
      "id" to resource.optString("id", ""),
      "title" to attributes.optString("name", ""),
      "artistName" to attributes.optString("artistName", ""),
      "artworkUrl" to artworkUrl(attributes.optJSONObject("artwork")),
      "trackCount" to attributes.optInt("trackCount", 0),
    )
  }

  fun mapArtist(resource: JSONObject): Map<String, Any?> {
    val attributes = resource.optJSONObject("attributes") ?: JSONObject()
    return mapOf(
      "id" to resource.optString("id", ""),
      "name" to attributes.optString("name", ""),
      "artworkUrl" to artworkUrl(attributes.optJSONObject("artwork")),
    )
  }

  fun mapPlaylist(resource: JSONObject): Map<String, Any?> {
    val attributes = resource.optJSONObject("attributes") ?: JSONObject()
    val trackCount =
      when {
        attributes.has("trackCount") -> attributes.optInt("trackCount", 0)
        else -> 0
      }
    return mapOf(
      "id" to resource.optString("id", ""),
      "name" to attributes.optString("name", ""),
      "description" to (
        attributes.optJSONObject("description")?.optString("standard", "")
          ?: attributes.optString("description", "")
      ),
      "artworkUrl" to artworkUrl(attributes.optJSONObject("artwork")),
      "trackCount" to trackCount,
    )
  }

  fun mapRecentResource(resource: JSONObject): Map<String, Any?> {
    val attributes = resource.optJSONObject("attributes") ?: JSONObject()
    val apiType = resource.optString("type", "")
    val itemType =
      when {
        apiType.contains("album") -> "album"
        apiType.contains("playlist") -> "playlist"
        apiType.contains("station") -> "station"
        else -> "unknown"
      }
    val subtitle =
      attributes.optString("artistName", "").ifEmpty {
        attributes.optString("curatorName", "").ifEmpty {
          attributes.optJSONObject("description")?.optString("standard", "") ?: ""
        }
      }
    return mapOf(
      "id" to resource.optString("id", ""),
      "title" to attributes.optString("name", ""),
      "subtitle" to subtitle,
      "type" to itemType,
    )
  }

  fun mapRecentlyPlayed(resource: JSONObject): Map<String, Any?> = mapRecentResource(resource)

  fun mapStation(resource: JSONObject): Map<String, Any?> {
    val attributes = resource.optJSONObject("attributes") ?: JSONObject()
    return mapOf(
      "id" to resource.optString("id", ""),
      "name" to attributes.optString("name", ""),
      "artworkUrl" to artworkUrl(attributes.optJSONObject("artwork")),
    )
  }

  fun mapMusicVideo(resource: JSONObject): Map<String, Any?> {
    val attributes = resource.optJSONObject("attributes") ?: JSONObject()
    val id = catalogPlaybackId(resource) ?: resource.optString("id", "")
    return mapOf<String, Any?>(
      "id" to id,
      "title" to attributes.optString("name", ""),
      "artistName" to attributes.optString("artistName", ""),
      "artworkUrl" to artworkUrl(attributes.optJSONObject("artwork")),
      "duration" to durationMillis(attributes),
    )
  }

  /** Maps ratings API envelope (`data[0].attributes.value`). */
  fun mapRating(json: JSONObject): Map<String, Any?>? {
    val data = json.optJSONArray("data") ?: return null
    if (data.length() == 0) return null
    val item = data.getJSONObject(0)
    val attributes = item.optJSONObject("attributes") ?: return null
    if (!attributes.has("value")) return null
    return mapOf(
      "id" to item.optString("id", ""),
      "value" to attributes.getInt("value"),
    )
  }

  fun mapRecommendation(resource: JSONObject): Map<String, Any?> {
    val attributes = resource.optJSONObject("attributes") ?: JSONObject()
    val title =
      attributes.optJSONObject("title")?.optString("stringForDisplay", "").orEmpty()
    val resourceTypes =
      attributes.optJSONArray("resourceTypes")?.let { array ->
        buildList(array.length()) {
          for (i in 0 until array.length()) {
            add(array.optString(i))
          }
        }
      } ?: emptyList()
    val contents = mapRecommendationContents(resource)
    return mapOf(
      "id" to resource.optString("id", ""),
      "title" to title,
      "resourceTypes" to resourceTypes,
      "playlists" to contents.playlists,
      "albums" to contents.albums,
      "stations" to contents.stations,
    )
  }

  fun mapReplaySummary(resource: JSONObject): Map<String, Any?> {
    val attributes = resource.optJSONObject("attributes") ?: JSONObject()
    val topSongs = mapRelationshipResources(resource, "top-songs", ::mapSong)
    val topAlbums = mapRelationshipResources(resource, "top-albums", ::mapAlbum)
    val topArtists = mapRelationshipResources(resource, "top-artists", ::mapArtist)
    return buildMap {
      put("id", resource.optString("id", ""))
      put("type", resource.optString("type", ""))
      put("name", attributes.optString("name", ""))
      put("topSongs", topSongs)
      put("topAlbums", topAlbums)
      put("topArtists", topArtists)
      if (attributes.has("year")) {
        put("year", attributes.optInt("year"))
      }
    }
  }

  private data class RecommendationContents(
    val playlists: List<Map<String, Any?>>,
    val albums: List<Map<String, Any?>>,
    val stations: List<Map<String, Any?>>,
  )

  private fun mapRecommendationContents(resource: JSONObject): RecommendationContents {
    val data =
      resource
        .optJSONObject("relationships")
        ?.optJSONObject("contents")
        ?.optJSONArray("data")
        ?: return RecommendationContents(emptyList(), emptyList(), emptyList())
    val playlists = buildList {
      for (i in 0 until data.length()) {
        val item = data.getJSONObject(i)
        if (item.optString("type", "").contains("playlist")) {
          add(mapPlaylist(item))
        }
      }
    }
    val albums = buildList {
      for (i in 0 until data.length()) {
        val item = data.getJSONObject(i)
        if (item.optString("type", "").contains("album")) {
          add(mapAlbum(item))
        }
      }
    }
    val stations = buildList {
      for (i in 0 until data.length()) {
        val item = data.getJSONObject(i)
        if (item.optString("type", "").contains("station")) {
          add(mapStation(item))
        }
      }
    }
    return RecommendationContents(playlists, albums, stations)
  }

  private fun mapRelationshipResources(
    resource: JSONObject,
    relationshipKey: String,
    mapper: (JSONObject) -> Map<String, Any?>,
  ): List<Map<String, Any?>> {
    val data =
      resource
        .optJSONObject("relationships")
        ?.optJSONObject(relationshipKey)
        ?.optJSONArray("data")
        ?: return emptyList()
    return buildList(data.length()) {
      for (i in 0 until data.length()) {
        add(mapper(data.getJSONObject(i)))
      }
    }
  }

  private fun durationMillis(attributes: JSONObject): Long {
    return when {
      attributes.has("durationInMillis") -> attributes.optLong("durationInMillis", 0)
      attributes.has("duration") -> (attributes.optDouble("duration", 0.0) * 1000).toLong()
      else -> 0L
    }
  }

  /** Catalog song id for [CatalogPlaybackQueueItemProvider] (playParams when present). */
  fun catalogPlaybackId(resource: JSONObject): String? {
    val playParams = resource.optJSONObject("attributes")?.optJSONObject("playParams") ?: return null
    return playParams.optString("id", "").takeIf { it.isNotEmpty() }
      ?: playParams.optString("catalogId", "").takeIf { it.isNotEmpty() }
  }

  private fun artworkUrl(artwork: JSONObject?, width: Int = 200, height: Int = 200): String {
    if (artwork == null) return ""
    val template = artwork.optString("url", "")
    if (template.isEmpty()) return ""
    return template
      .replace("{w}", width.toString())
      .replace("{h}", height.toString())
  }
}
