import Foundation
@testable import RestJsonMapperLib
import XCTest

/**
 Mirror of `BRIDGE_CONTRACT_CASES` / Android `BridgeContractTest` for iOS `RestJsonMapper`.

 Full MusicItemMapper (MusicKit Song/Album) cases need MusicKit types; pure duration /
 playParams helpers are covered below via `BridgeMapperHelpers`.
 */
final class BridgeContractTests: XCTestCase {
  private func fixturesRoot() -> URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent() // BridgeContractTests
      .deletingLastPathComponent() // Tests
      .deletingLastPathComponent() // BridgeContractPackage
      .deletingLastPathComponent() // ios
      .deletingLastPathComponent() // repo root
      .appendingPathComponent("fixtures")
  }

  private func loadJSON(_ relativePath: String) throws -> [String: Any] {
    let url = fixturesRoot().appendingPathComponent(relativePath)
    let data = try Data(contentsOf: url)
    let object = try JSONSerialization.jsonObject(with: data)
    guard let dict = object as? [String: Any] else {
      throw NSError(
        domain: "BridgeContractTests",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Expected object JSON at \(relativePath)"]
      )
    }
    return dict
  }

  private func assertBridgeEqual(
    _ actual: [String: Any]?,
    expectedFile: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) throws {
    let expected = try loadJSON("expected/\(expectedFile)")
    guard let actual else {
      XCTFail("Mapper returned nil", file: file, line: line)
      return
    }
    let actualData = try JSONSerialization.data(withJSONObject: actual, options: [.sortedKeys])
    let expectedData = try JSONSerialization.data(withJSONObject: expected, options: [.sortedKeys])
    let actualJSON = String(data: actualData, encoding: .utf8) ?? ""
    let expectedJSON = String(data: expectedData, encoding: .utf8) ?? ""
    XCTAssertEqual(actualJSON, expectedJSON, file: file, line: line)
  }

  func testMapSongCatalogResource() throws {
    let input = try loadJSON("catalog-song.json")
    try assertBridgeEqual(RestJsonMapper.mapSong(input), expectedFile: "song.catalog.json")
  }

  func testMapAlbumCatalogResource() throws {
    let input = try loadJSON("catalog-album.json")
    try assertBridgeEqual(RestJsonMapper.mapAlbum(input), expectedFile: "album.catalog.json")
  }

  func testMapArtistLibraryResource() throws {
    let input = try loadJSON("library-artist.json")
    try assertBridgeEqual(RestJsonMapper.mapArtist(input), expectedFile: "artist.library.json")
  }

  func testMapPlaylistCatalogResource() throws {
    let input = try loadJSON("catalog-playlist.json")
    try assertBridgeEqual(RestJsonMapper.mapPlaylist(input), expectedFile: "playlist.catalog.json")
  }

  func testMapRecentResourceLibraryAlbum() throws {
    let input = try loadJSON("library-recent-album.json")
    try assertBridgeEqual(
      RestJsonMapper.mapRecentResource(input),
      expectedFile: "recent-resource.library-album.json"
    )
  }

  func testMapRatingLike() throws {
    let input = try loadJSON("ratings-response.json")
    try assertBridgeEqual(RestJsonMapper.mapRating(input), expectedFile: "rating.like.json")
  }

  func testDurationMillisFromSeconds() {
    XCTAssertEqual(BridgeMapperHelpers.durationMillis(fromSeconds: nil), 0)
    XCTAssertEqual(BridgeMapperHelpers.durationMillis(fromSeconds: 0), 0)
    XCTAssertEqual(BridgeMapperHelpers.durationMillis(fromSeconds: 1.5), 1500)
    XCTAssertEqual(BridgeMapperHelpers.durationMillis(fromSeconds: 212.345), 212_345)
  }

  func testCatalogPlaybackIdFromPlayParams() {
    XCTAssertNil(BridgeMapperHelpers.catalogPlaybackId(fromPlayParams: nil))
    XCTAssertNil(BridgeMapperHelpers.catalogPlaybackId(fromPlayParams: [:]))
    XCTAssertNil(BridgeMapperHelpers.catalogPlaybackId(fromPlayParams: ["id": ""]))
    XCTAssertEqual(
      BridgeMapperHelpers.catalogPlaybackId(fromPlayParams: ["id": "catalog.song.1"]),
      "catalog.song.1"
    )
    XCTAssertEqual(
      BridgeMapperHelpers.catalogPlaybackId(fromPlayParams: ["catalogId": "c.2"]),
      "c.2"
    )
    XCTAssertEqual(
      BridgeMapperHelpers.catalogPlaybackId(fromPlayParams: ["id": "primary", "catalogId": "alt"]),
      "primary"
    )
  }
}
