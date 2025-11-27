// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        .binaryTarget(
            name: "SpeedManagerModule",
            url: "https://github.com/billypchan/SpeedManagerModule/releases/download/0.2/SpeedManagerModule.xcframework.zip",
            checksum: "b64333457922e9d8cca4e725ce008fcc842e5919a40e66e46ac824e20175f49d"
        ),
        .testTarget(
            name: "SpeedManagerModuleTests",
            dependencies: ["SpeedManagerModule"]),
    ],
    swiftLanguageVersions: [SwiftVersion.v5]
)
