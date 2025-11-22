#!/bin/bash

# Build Dynamic XCFramework for SpeedManagerModule (Direct Approach)
# This script builds frameworks directly without archives

set -e

echo "🚀 Building Dynamic XCFramework for SpeedManagerModule..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf Build/DerivedData
rm -rf Build/Frameworks
mkdir -p Build/Frameworks

# Build for iOS Device (arm64)
echo "📱 Building for iOS Device (arm64)..."
xcodebuild -scheme SpeedManagerModule \
    -destination "generic/platform=iOS" \
    -derivedDataPath "Build/DerivedData" \
    -sdk iphoneos \
    -configuration Release \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    MACH_O_TYPE=mh_dylib \
    PRODUCT_NAME=SpeedManagerModule \
    build

# Copy iOS Device framework
cp -R "Build/DerivedData/Build/Products/Release-iphoneos/SpeedManagerModule.framework" "Build/Frameworks/SpeedManagerModule-iOS.framework"

# Build for iOS Simulator (arm64)
echo "🖥️ Building for iOS Simulator (arm64)..."
xcodebuild -scheme SpeedManagerModule \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath "Build/DerivedData" \
    -sdk iphonesimulator \
    -configuration Release \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    MACH_O_TYPE=mh_dylib \
    PRODUCT_NAME=SpeedManagerModule \
    build

# Copy iOS Simulator framework
cp -R "Build/DerivedData/Build/Products/Release-iphonesimulator/SpeedManagerModule.framework" "Build/Frameworks/SpeedManagerModule-iOS-Simulator.framework"

# Build for watchOS Device
echo "⌚ Building for watchOS Device..."
xcodebuild -scheme SpeedManagerModule \
    -destination "generic/platform=watchOS" \
    -derivedDataPath "Build/DerivedData" \
    -sdk watchos \
    -configuration Release \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    MACH_O_TYPE=mh_dylib \
    PRODUCT_NAME=SpeedManagerModule \
    build

# Copy watchOS Device framework
cp -R "Build/DerivedData/Build/Products/Release-watchos/SpeedManagerModule.framework" "Build/Frameworks/SpeedManagerModule-watchOS.framework"

# Build for watchOS Simulator
echo "⌚🖥️ Building for watchOS Simulator..."
xcodebuild -scheme SpeedManagerModule \
    -destination "generic/platform=watchOS Simulator" \
    -derivedDataPath "Build/DerivedData" \
    -sdk watchsimulator \
    -configuration Release \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    MACH_O_TYPE=mh_dylib \
    PRODUCT_NAME=SpeedManagerModule \
    build

# Copy watchOS Simulator framework
cp -R "Build/DerivedData/Build/Products/Release-watchsimulator/SpeedManagerModule.framework" "Build/Frameworks/SpeedManagerModule-watchOS-Simulator.framework"

# Create XCFramework
echo "🔧 Creating XCFramework..."
rm -rf Build/SpeedManagerModule.xcframework

xcodebuild -create-xcframework \
    -framework "Build/Frameworks/SpeedManagerModule-iOS.framework" \
    -framework "Build/Frameworks/SpeedManagerModule-iOS-Simulator.framework" \
    -framework "Build/Frameworks/SpeedManagerModule-watchOS.framework" \
    -framework "Build/Frameworks/SpeedManagerModule-watchOS-Simulator.framework" \
    -output "Build/SpeedManagerModule.xcframework"

# Verify the created frameworks
echo "🔍 Verifying created frameworks..."
for framework in Build/SpeedManagerModule.xcframework/*/SpeedManagerModule.framework/SpeedManagerModule; do
    if [ -f "$framework" ]; then
        echo "📋 $(dirname $(dirname $framework)):"
        file "$framework"
        echo "Library dependencies:"
        otool -L "$framework" | head -5
        echo "Exported symbols (first 10):"
        nm -D "$framework" 2>/dev/null | head -10 || echo "  (Static binary - checking symbol table)"
        nm "$framework" 2>/dev/null | grep "SpeedManager" | head -5 || echo "  No SpeedManager symbols found"
        echo ""
    fi
done

# Create ZIP for distribution
echo "📦 Creating distribution ZIP..."
cd Build
zip -r SpeedManagerModule.xcframework.zip SpeedManagerModule.xcframework
cd ..

echo "✅ Dynamic XCFramework build complete!"
echo "📊 Framework info:"
du -sh Build/SpeedManagerModule.xcframework
ls -lh Build/SpeedManagerModule.xcframework.zip