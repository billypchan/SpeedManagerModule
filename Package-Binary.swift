// swift-tools-version: 5.9
// Binary distribution version of SpeedManagerModule Package

import PackageDescription

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
    targets: [
        // Local binary target for development and testing
        .binaryTarget(
            name: "SpeedManagerModule",
            path: "./Build/SpeedManagerModule.xcframework"
        ),
        
        // For release distribution, use:
        // .binaryTarget(
        //     name: "SpeedManagerModule",
        //     url: "https://github.com/billypchan/SpeedManagerModule/releases/download/v0.1.1/SpeedManagerModule.xcframework.zip",
        //     checksum: "fb70985432a4a8ca2d282e015fbef910a5a7e32cbc9bbff3578f6ae5854ec7eb"
        // ),
    ],
    swiftLanguageVersions: [SwiftVersion.v5]
)