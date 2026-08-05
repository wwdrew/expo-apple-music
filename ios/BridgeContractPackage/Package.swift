// swift-tools-version: 5.9
import PackageDescription

/// Hosts XCTest cases for `RestJsonMapper` against repo `fixtures/`.
/// `Sources/RestJsonMapperLib/RestJsonMapper.swift` is a symlink to `ios/RestJsonMapper.swift`.
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
