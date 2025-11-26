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

# Build iOS Device (arm64)
echo "📱 Building archive for iOS Device..."
xcodebuild archive \
    -scheme SpeedManagerModule \
    -destination "generic/platform=iOS" \
    -archivePath "Build/Archives/SpeedManagerModule-iOS.xcarchive" \
    -derivedDataPath "Build/DerivedData" \
    -sdk iphoneos \
    -configuration Release \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    ARCHS=arm64 \
    ONLY_ACTIVE_ARCH=NO

# Build iOS Simulator (arm64 + x86_64)
echo "🖥️ Building archive for iOS Simulator..."
xcodebuild archive \
    -scheme SpeedManagerModule \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "Build/Archives/SpeedManagerModule-iOS-Simulator.xcarchive" \
    -derivedDataPath "Build/DerivedData" \
    -sdk iphonesimulator \
    -configuration Release \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO

# Build watchOS Device (arm64_32)
echo "⌚ Building archive for watchOS Device..."
xcodebuild archive \
    -scheme SpeedManagerModule \
    -destination "generic/platform=watchOS" \
    -archivePath "Build/Archives/SpeedManagerModule-watchOS.xcarchive" \
    -derivedDataPath "Build/DerivedData" \
    -sdk watchos \
    -configuration Release \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    ARCHS=arm64_32 \
    ONLY_ACTIVE_ARCH=NO

# Build watchOS Simulator (arm64 + x86_64)
echo "⌚🖥️ Building archive for watchOS Simulator..."
xcodebuild archive \
    -scheme SpeedManagerModule \
    -destination "generic/platform=watchOS Simulator" \
    -archivePath "Build/Archives/SpeedManagerModule-watchOS-Simulator.xcarchive" \
    -derivedDataPath "Build/DerivedData" \
    -sdk watchsimulator \
    -configuration Release \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO

# Build macOS (arm64 + x86_64)
echo "💻 Building archive for macOS..."
xcodebuild archive \
    -scheme SpeedManagerModule \
    -destination "generic/platform=macOS" \
    -archivePath "Build/Archives/SpeedManagerModule-macOS.xcarchive" \
    -derivedDataPath "Build/DerivedData" \
    -sdk macosx \
    -configuration Release \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    ARCHS="arm64 x86_64" \
    ONLY_ACTIVE_ARCH=NO

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