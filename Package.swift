// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SpeedManagerModule",
    platforms: [
        .macOS(.v12),
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "SpeedManagerModule",
            targets: ["SpeedManagerModule"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .binaryTarget(
            name: "SpeedManagerModule",
            url: "https://github.com/yourorg/SpeedManagerModule/releases/download/1.0.0/SpeedManagerModule.xcframework.zip",
            checksum: "b1f79eee9bd0f41f0f2fcca1c1efe48588d9ea3d707ca4b9d425969b221d1876"
        )
    ]
)
