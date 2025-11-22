#!/bin/bash

# XCFramework build script for Swift Package Manager projects
# Compatible with Swift 5.9+ and modern Xcode versions

set -e

FRAMEWORK_NAME="SpeedManagerModule"
OUTPUT_DIR="./Build"
XCFRAMEWORK_PATH="$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"
WORK_DIR="$OUTPUT_DIR/Work"

echo "🚀 Building XCFramework for $FRAMEWORK_NAME"
echo "============================================="

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$WORK_DIR"

# Function to build for a specific destination
build_framework_for_destination() {
    local destination="$1"
    local platform="$2"
    local sdk="$3"
    
    echo "🔨 Building for $platform ($sdk)..."
    
    # Create a temporary directory for this build
    local temp_dir="$WORK_DIR/$platform"
    mkdir -p "$temp_dir"
    
    # Build the package for this destination
    swift build \
        -c release \
        --build-path "$temp_dir/.build" \
        --triple "$destination"
    
    # Locate the built library/module
    local lib_path
    lib_path=$(find "$temp_dir/.build" -name "lib$FRAMEWORK_NAME.a" | head -1)
    
    if [ -z "$lib_path" ]; then
        # Try alternative patterns
        lib_path=$(find "$temp_dir/.build" -path "*/$FRAMEWORK_NAME" -o -name "*$FRAMEWORK_NAME*" -type f | head -1)
    fi
    
    if [ -z "$lib_path" ] || [ ! -f "$lib_path" ]; then
        echo "❌ Could not find built library for $platform"
        echo "Available files:"
        find "$temp_dir/.build" -type f -name "*$FRAMEWORK_NAME*" 2>/dev/null || echo "None found"
        return 1
    fi
    
    # Create framework structure
    local framework_dir="$WORK_DIR/$platform.framework"
    mkdir -p "$framework_dir"
    
    # Copy the library
    cp "$lib_path" "$framework_dir/$FRAMEWORK_NAME"
    
    # Create Info.plist
    local min_version
    case "$platform" in
        *watchOS*) min_version="8.0" ;;
        *iOS*) min_version="15.0" ;;
        *) min_version="12.0" ;;
    esac
    
    cat > "$framework_dir/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$FRAMEWORK_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.speedmanager.$FRAMEWORK_NAME</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$FRAMEWORK_NAME</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>$min_version</string>
</dict>
</plist>
EOF
    
    # Create module map
    mkdir -p "$framework_dir/Modules"
    cat > "$framework_dir/Modules/module.modulemap" << EOF
framework module $FRAMEWORK_NAME {
    export *
    module * { export * }
}
EOF
    
    # Copy Swift module files if they exist
    local swift_modules_dir
    swift_modules_dir=$(find "$temp_dir/.build" -type d -name "$FRAMEWORK_NAME.swiftmodule" | head -1)
    if [ -n "$swift_modules_dir" ] && [ -d "$swift_modules_dir" ]; then
        cp -r "$swift_modules_dir" "$framework_dir/Modules/"
    fi
    
    echo "✅ Framework created for $platform"
    echo "$framework_dir"
}

# Build for all required platforms
echo "🏗️  Building for all platforms..."

# Try to build for iOS (device)
if IOS_FRAMEWORK=$(build_framework_for_destination "arm64-apple-ios15.0" "iOS" "iphoneos"); then
    echo "✅ iOS device build successful"
else
    echo "❌ iOS device build failed"
    IOS_FRAMEWORK=""
fi

# Try to build for iOS Simulator
if IOS_SIM_FRAMEWORK=$(build_framework_for_destination "arm64-apple-ios15.0-simulator" "iOS-Simulator" "iphonesimulator"); then
    echo "✅ iOS Simulator build successful"
else
    echo "❌ iOS Simulator build failed - trying x86_64"
    if IOS_SIM_FRAMEWORK=$(build_framework_for_destination "x86_64-apple-ios15.0-simulator" "iOS-Simulator" "iphonesimulator"); then
        echo "✅ iOS Simulator (x86_64) build successful"
    else
        echo "❌ iOS Simulator build failed"
        IOS_SIM_FRAMEWORK=""
    fi
fi

# Try to build for watchOS (device)
if WATCHOS_FRAMEWORK=$(build_framework_for_destination "arm64_32-apple-watchos8.0" "watchOS" "watchos"); then
    echo "✅ watchOS device build successful"
else
    echo "❌ watchOS device build failed"
    WATCHOS_FRAMEWORK=""
fi

# Try to build for watchOS Simulator
if WATCHOS_SIM_FRAMEWORK=$(build_framework_for_destination "arm64-apple-watchos8.0-simulator" "watchOS-Simulator" "watchsimulator"); then
    echo "✅ watchOS Simulator build successful"
else
    echo "❌ watchOS Simulator build failed - trying x86_64"
    if WATCHOS_SIM_FRAMEWORK=$(build_framework_for_destination "x86_64-apple-watchos8.0-simulator" "watchOS-Simulator" "watchsimulator"); then
        echo "✅ watchOS Simulator (x86_64) build successful"
    else
        echo "❌ watchOS Simulator build failed"
        WATCHOS_SIM_FRAMEWORK=""
    fi
fi

# Check if we have at least some frameworks
FRAMEWORK_ARGS=()
[ -n "$IOS_FRAMEWORK" ] && FRAMEWORK_ARGS+=(-framework "$IOS_FRAMEWORK")
[ -n "$IOS_SIM_FRAMEWORK" ] && FRAMEWORK_ARGS+=(-framework "$IOS_SIM_FRAMEWORK")
[ -n "$WATCHOS_FRAMEWORK" ] && FRAMEWORK_ARGS+=(-framework "$WATCHOS_FRAMEWORK")
[ -n "$WATCHOS_SIM_FRAMEWORK" ] && FRAMEWORK_ARGS+=(-framework "$WATCHOS_SIM_FRAMEWORK")

if [ ${#FRAMEWORK_ARGS[@]} -eq 0 ]; then
    echo "❌ No frameworks were built successfully"
    echo "💡 This might be because Swift Package Manager doesn't support all target platforms"
    echo "    or the build environment needs adjustment."
    echo ""
    echo "🔄 Falling back to source distribution..."
    ./build-source-distribution.sh
    exit 0
fi

# Create XCFramework
echo "🔨 Creating XCFramework with available frameworks..."
echo "Frameworks: ${FRAMEWORK_ARGS[*]}"

if xcodebuild -create-xcframework \
    "${FRAMEWORK_ARGS[@]}" \
    -output "$XCFRAMEWORK_PATH"; then
    
    echo "✅ XCFramework created successfully!"
    
    # Create distribution package
    echo "📦 Creating distribution package..."
    cd "$OUTPUT_DIR"
    
    # Compress the XCFramework
    zip -r "$FRAMEWORK_NAME.xcframework.zip" "$FRAMEWORK_NAME.xcframework"
    
    # Compute checksum
    if command -v swift &> /dev/null; then
        CHECKSUM=$(swift package compute-checksum "$FRAMEWORK_NAME.xcframework.zip" 2>/dev/null || shasum -a 256 "$FRAMEWORK_NAME.xcframework.zip" | cut -d' ' -f1)
    else
        CHECKSUM=$(shasum -a 256 "$FRAMEWORK_NAME.xcframework.zip" | cut -d' ' -f1)
    fi
    echo "$CHECKSUM" > "$FRAMEWORK_NAME.xcframework.zip.checksum"
    
    # Create binary Package.swift
    cat > "Package-Binary.swift" << EOF
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "$FRAMEWORK_NAME",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "$FRAMEWORK_NAME",
            targets: ["$FRAMEWORK_NAME"]),
    ],
    targets: [
        .binaryTarget(
            name: "$FRAMEWORK_NAME",
            url: "https://github.com/your-username/your-repo/releases/download/v1.0.0/$FRAMEWORK_NAME.xcframework.zip",
            checksum: "$CHECKSUM"
        ),
    ]
)
EOF
    
    echo ""
    echo "🎉 XCFramework build completed successfully!"
    echo "================================================="
    echo "📱 XCFramework: $XCFRAMEWORK_PATH"
    echo "📦 Compressed: $OUTPUT_DIR/$FRAMEWORK_NAME.xcframework.zip"
    echo "🔐 Checksum: $CHECKSUM"
    echo "📄 Binary Package: $OUTPUT_DIR/Package-Binary.swift"
    echo ""
    echo "🚀 Ready for distribution!"
    
else
    echo "❌ Failed to create XCFramework"
    echo "🔄 Creating source distribution instead..."
    ./build-source-distribution.sh
fi