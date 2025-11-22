#!/bin/bash

# Build Static XCFramework for SpeedManagerModule
# This script builds static frameworks for all platforms

set -e

echo "🚀 Building Static XCFramework for SpeedManagerModule..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf Build/DerivedData
rm -rf Build/Archives
mkdir -p Build/Archives

# Function to build and archive for a platform
build_archive() {
    local platform=$1
    local sdk=$2
    local destination=$3
    local arch_setting=$4
    
    echo "📱 Building archive for $platform..."
    
    xcodebuild archive \
        -scheme SpeedManagerModule \
        -destination "$destination" \
        -archivePath "Build/Archives/SpeedManagerModule-$platform.xcarchive" \
        -derivedDataPath "Build/DerivedData" \
        -sdk $sdk \
        -configuration Release \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO \
        $arch_setting \
        ONLY_ACTIVE_ARCH=NO
}

# Build iOS Device (arm64)
build_archive "iOS" "iphoneos" "generic/platform=iOS" "ARCHS=arm64"

# Build iOS Simulator (arm64 + x86_64)  
build_archive "iOS-Simulator" "iphonesimulator" "generic/platform=iOS Simulator" 'ARCHS="arm64 x86_64"'

# Build watchOS Device (arm64_32)
build_archive "watchOS" "watchos" "generic/platform=watchOS" "ARCHS=arm64_32"

# Build watchOS Simulator (arm64 + x86_64)
build_archive "watchOS-Simulator" "watchsimulator" "generic/platform=watchOS Simulator" 'ARCHS="arm64 x86_64"'

# Build macOS (arm64 + x86_64)
build_archive "macOS" "macosx" "generic/platform=macOS" 'ARCHS="arm64 x86_64"'

# Create XCFramework from archives
echo "🔧 Creating XCFramework from archives..."
rm -rf Build/SpeedManagerModule.xcframework

xcodebuild -create-xcframework \
    -archive "Build/Archives/SpeedManagerModule-iOS.xcarchive" -framework SpeedManagerModule.framework \
    -archive "Build/Archives/SpeedManagerModule-iOS-Simulator.xcarchive" -framework SpeedManagerModule.framework \
    -archive "Build/Archives/SpeedManagerModule-watchOS.xcarchive" -framework SpeedManagerModule.framework \
    -archive "Build/Archives/SpeedManagerModule-watchOS-Simulator.xcarchive" -framework SpeedManagerModule.framework \
    -archive "Build/Archives/SpeedManagerModule-macOS.xcarchive" -framework SpeedManagerModule.framework \
    -output "Build/SpeedManagerModule.xcframework"

# Verify the created frameworks
echo "🔍 Verifying created frameworks..."
for framework_path in Build/SpeedManagerModule.xcframework/*/SpeedManagerModule.framework; do
    if [ -d "$framework_path" ]; then
        binary_path="$framework_path/SpeedManagerModule"
        if [ -f "$binary_path" ]; then
            echo "📋 $(dirname $framework_path):"
            file "$binary_path"
            echo "Architectures:"
            lipo -archs "$binary_path" 2>/dev/null || echo "  Could not determine architectures"
            echo "Symbols (first 5 SpeedManager symbols):"
            nm "$binary_path" 2>/dev/null | grep "SpeedManager" | head -5 || echo "  No SpeedManager symbols found"
            echo ""
        fi
    fi
done

# Sign the XCFramework
echo "🔏 Signing XCFramework..."
codesign --sign "Chan Bill" --timestamp --force --deep Build/SpeedManagerModule.xcframework

# Verify signing
echo "🔍 Verifying signature..."
codesign -dv Build/SpeedManagerModule.xcframework
spctl -a -v Build/SpeedManagerModule.xcframework

# Create ZIP for distribution
echo "📦 Creating distribution ZIP..."
cd Build
zip -r SpeedManagerModule.xcframework.zip SpeedManagerModule.xcframework
cd ..

echo "✅ Static XCFramework build complete!"
echo "📊 Framework info:"
du -sh Build/SpeedManagerModule.xcframework
ls -lh Build/SpeedManagerModule.xcframework.zip

# Show final architecture summary
echo ""
echo "🏗️ Final Architecture Summary:"
for framework_path in Build/SpeedManagerModule.xcframework/*/SpeedManagerModule.framework; do
    if [ -d "$framework_path" ]; then
        binary_path="$framework_path/SpeedManagerModule"
        if [ -f "$binary_path" ]; then
            platform_dir=$(dirname $framework_path)
            platform_name=$(basename $platform_dir)
            archs=$(lipo -archs "$binary_path" 2>/dev/null || echo "unknown")
            echo "  $platform_name: $archs"
        fi
    fi
done