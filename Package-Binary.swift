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
        // Binary target for distribution
        .binaryTarget(
            name: "SpeedManagerModule",
            // Replace with your actual release URL and checksum
            url: "https://github.com/billypchan/SpeedManagerModule/releases/download/v1.0.0/SpeedManagerModule.xcframework.zip",
            checksum: "REPLACE_WITH_ACTUAL_CHECKSUM"
        ),
        
        // Uncomment below for local XCFramework during development
        // .binaryTarget(
        //     name: "SpeedManagerModule",
        //     path: "./Build/SpeedManagerModule.xcframework"
        // ),
    ],
    swiftLanguageVersions: [SwiftVersion.v5]
)