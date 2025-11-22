#!/bin/bash

set -e

echo "🚀 Creating XCFramework for SpeedManagerModule"
echo "=============================================="

# Clean previous builds
rm -rf Build/SpeedManagerModule.xcframework
rm -rf Build/Libraries
mkdir -p Build/Libraries

echo "📦 Building static libraries for each platform..."

# Build for iOS Device (arm64)
echo "📱 Building iOS Device library..."
xcodebuild -scheme SpeedManagerModule \
    -destination "generic/platform=iOS" \
    -derivedDataPath Build/DerivedData/iOS \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    MACH_O_TYPE=staticlib

# Build for iOS Simulator (x86_64)
echo "📱 Building iOS Simulator library..."  
xcodebuild -scheme SpeedManagerModule \
    -destination "generic/platform=iOS Simulator" \
    -derivedDataPath Build/DerivedData/iOS-Simulator \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    MACH_O_TYPE=staticlib

# Build for watchOS Device
echo "⌚ Building watchOS Device library..."
xcodebuild -scheme SpeedManagerModule \
    -destination "generic/platform=watchOS" \
    -derivedDataPath Build/DerivedData/watchOS \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    MACH_O_TYPE=staticlib

# Build for watchOS Simulator
echo "⌚ Building watchOS Simulator library..."
xcodebuild -scheme SpeedManagerModule \
    -destination "generic/platform=watchOS Simulator" \
    -derivedDataPath Build/DerivedData/watchOS-Simulator \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    MACH_O_TYPE=staticlib

# Build for macOS
echo "🖥️  Building macOS library..."
xcodebuild -scheme SpeedManagerModule \
    -destination "generic/platform=macOS" \
    -derivedDataPath Build/DerivedData/macOS \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO \
    MACH_O_TYPE=staticlib

echo "🔍 Finding built libraries..."
find Build/DerivedData -name "libSpeedManagerModule.a" -o -name "SpeedManagerModule.o"

echo "✅ Static library builds completed!"
echo "Next: Create XCFramework from the built libraries"