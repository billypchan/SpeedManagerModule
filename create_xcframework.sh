#!/bin/bash

set -e

PROJECT_NAME="SpeedManagerModule"
SCHEME_NAME="SpeedManagerModule"
FRAMEWORK_NAME="${PROJECT_NAME}.framework"
XCFRAMEWORK_NAME="${PROJECT_NAME}.xcframework"

echo "Building for all platforms..."

# Build for iOS Device
echo "Building iOS Device (arm64)..."
xcodebuild build -scheme $SCHEME_NAME -destination "generic/platform=iOS" -configuration Release BUILD_LIBRARY_FOR_DISTRIBUTION=YES ARCHS=arm64

# Build for iOS Simulator 
echo "Building iOS Simulator (arm64)..."
xcodebuild build -scheme $SCHEME_NAME -destination "generic/platform=iOS Simulator" -configuration Release BUILD_LIBRARY_FOR_DISTRIBUTION=YES ARCHS=arm64

# Build for macOS
echo "Building macOS (arm64)..."
xcodebuild build -scheme $SCHEME_NAME -destination "generic/platform=macOS" -configuration Release BUILD_LIBRARY_FOR_DISTRIBUTION=YES ARCHS=arm64

# Build for watchOS
echo "Building watchOS (arm64)..."  
xcodebuild build -scheme $SCHEME_NAME -destination "generic/platform=watchOS" -configuration Release BUILD_LIBRARY_FOR_DISTRIBUTION=YES ARCHS=arm64

# Build for watchOS Simulator
echo "Building watchOS Simulator (arm64)..."
xcodebuild build -scheme $SCHEME_NAME -destination "generic/platform=watchOS Simulator" -configuration Release BUILD_LIBRARY_FOR_DISTRIBUTION=YES ARCHS=arm64

echo "Creating framework structures..."

# Clean up
rm -rf frameworks

# Create framework directories
mkdir -p frameworks

# Function to create framework structure
create_framework() {
    local platform=$1
    local platform_name=$2
    local min_version=$3
    local supported_platforms=$4
    local platform_dir=$5
    
    FRAMEWORK_DIR="frameworks/${platform}/${FRAMEWORK_NAME}"
    mkdir -p "${FRAMEWORK_DIR}/Modules"
    mkdir -p "${FRAMEWORK_DIR}/Headers"
    
    # Find the correct derived data path for this platform
    DERIVED_DATA_BASE=$(find ~/Library/Developer/Xcode/DerivedData/SpeedManagerModule-*/Build/Products/${platform_dir} -name "*.swiftmodule" | head -1 | xargs dirname 2>/dev/null)
    
    if [ -z "$DERIVED_DATA_BASE" ]; then
        echo "Warning: Could not find build products for $platform in ${platform_dir}"
        return
    fi
    
    echo "Using build products from: $DERIVED_DATA_BASE"
    
    # Copy Swift module files
    if [ -d "${DERIVED_DATA_BASE}/${PROJECT_NAME}.swiftmodule" ]; then
        cp -r "${DERIVED_DATA_BASE}/${PROJECT_NAME}.swiftmodule"/* "${FRAMEWORK_DIR}/Modules/" 2>/dev/null || true
    fi
    
    # Copy binary
    if [ -f "${DERIVED_DATA_BASE}/${PROJECT_NAME}.o" ]; then
        cp "${DERIVED_DATA_BASE}/${PROJECT_NAME}.o" "${FRAMEWORK_DIR}/${PROJECT_NAME}"
    fi
    
    # Create Info.plist
    cat > "${FRAMEWORK_DIR}/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${PROJECT_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.speedmanagermodule.${PROJECT_NAME}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${PROJECT_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>${supported_platforms}</string>
    </array>
    <key>MinimumOSVersion</key>
    <string>${min_version}</string>
</dict>
</plist>
EOF

    # Create module.modulemap
    cat > "${FRAMEWORK_DIR}/Modules/module.modulemap" << EOF
framework module ${PROJECT_NAME} {
    umbrella header "${PROJECT_NAME}.h"
    
    export *
    module * { export * }
}
EOF

    # Create umbrella header
    cat > "${FRAMEWORK_DIR}/Headers/${PROJECT_NAME}.h" << EOF
//
//  ${PROJECT_NAME}.h
//  ${PROJECT_NAME}
//
//  Created by Swift Package Manager.
//

#import <Foundation/Foundation.h>

//! Project version number for ${PROJECT_NAME}.
FOUNDATION_EXPORT double ${PROJECT_NAME}VersionNumber;

//! Project version string for ${PROJECT_NAME}.
FOUNDATION_EXPORT const unsigned char ${PROJECT_NAME}VersionString[];
EOF

    echo "Created framework for $platform_name"
}

# Create frameworks for all platforms
create_framework "ios-arm64" "iOS Device" "15.0" "iPhoneOS" "Release-iphoneos"
create_framework "ios-arm64-simulator" "iOS Simulator" "15.0" "iPhoneSimulator" "Release-iphonesimulator"  
create_framework "macos-arm64" "macOS" "12.0" "MacOSX" "Release"
create_framework "watchos-arm64" "watchOS" "8.0" "WatchOS" "Release-watchos"
create_framework "watchos-arm64-simulator" "watchOS Simulator" "8.0" "WatchSimulator" "Release-watchsimulator"

echo "Creating XCFramework..."

# Build framework arguments
FRAMEWORK_ARGS=""

# Add frameworks that exist
for platform in ios-arm64 ios-arm64-simulator macos-arm64 watchos-arm64 watchos-arm64-simulator; do
    if [ -d "frameworks/${platform}/${FRAMEWORK_NAME}" ]; then
        FRAMEWORK_ARGS="${FRAMEWORK_ARGS} -framework frameworks/${platform}/${FRAMEWORK_NAME}"
        echo "Adding $platform framework"
    else
        echo "Warning: $platform framework not found"
    fi
done

if [ -z "$FRAMEWORK_ARGS" ]; then
    echo "Error: No frameworks were created successfully"
    exit 1
fi

echo "Framework arguments: $FRAMEWORK_ARGS"

# Create XCFramework
xcodebuild -create-xcframework $FRAMEWORK_ARGS -output "${XCFRAMEWORK_NAME}"

echo "Creating ZIP archive..."
zip -r "${XCFRAMEWORK_NAME}.zip" "${XCFRAMEWORK_NAME}"

echo "Calculating checksum..."
CHECKSUM=$(swift package compute-checksum "${XCFRAMEWORK_NAME}.zip")
echo $CHECKSUM

echo "Done! XCFramework created successfully."
echo "File: ${XCFRAMEWORK_NAME}.zip"
echo "Checksum: $CHECKSUM"
echo "Use the checksum above in your Package.swift file."