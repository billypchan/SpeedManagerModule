// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

// Set to true to use binary distribution, false for source distribution
let useBinaryTarget = false

let package = Package(
    name: "SpeedManagerModule",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8)
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
    targets: useBinaryTarget ? [
        // Binary distribution target
        .binaryTarget(
            name: "SpeedManagerModule",
            path: "./Build/SpeedManagerModule.xcframework"
        ),
        
        // For release distribution, replace the path-based binary target above with:
        // .binaryTarget(
        //     name: "SpeedManagerModule",
        //     url: "https://github.com/billypchan/SpeedManagerModule/releases/download/v0.1.1/SpeedManagerModule.xcframework.zip",
        //     checksum: "fb70985432a4a8ca2d282e015fbef910a5a7e32cbc9bbff3578f6ae5854ec7eb"
        // ),
    ] : [
        // Source distribution targets
        .target(
            name: "SpeedManagerModule",
            dependencies: []),
        .testTarget(
            name: "SpeedManagerModuleTests",
            dependencies: ["SpeedManagerModule"]),
    ],
    swiftLanguageVersions: [SwiftVersion.v5]
)
