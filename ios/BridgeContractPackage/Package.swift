// swift-tools-version: 5.9
import PackageDescription

/// Hosts XCTest cases for `RestJsonMapper` + pure mapper helpers against repo `fixtures/`.
/// Sources under `RestJsonMapperLib/` are symlinks to `ios/*.swift`.
/// Run: `yarn test:ios-bridge` (macOS) or see docs/BRIDGE_CONTRACT.md.
let package = Package(
  name: "BridgeContractPackage",
  platforms: [
    .macOS(.v13),
  ],
  products: [
    .library(name: "RestJsonMapperLib", targets: ["RestJsonMapperLib"]),
  ],
  targets: [
    .target(
      name: "RestJsonMapperLib"
    ),
    .testTarget(
      name: "BridgeContractTests",
      dependencies: ["RestJsonMapperLib"]
    ),
  ]
)
