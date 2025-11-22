#!/bin/bash

set -e

echo "🚀 Building real XCFramework with binaries..."

# Clean up
rm -rf Build
rm -rf .build
rm -rf .swiftpm

# Create workspace structure manually since we can't use the built components easily
echo "📦 Creating framework structure manually..."

# Build for iOS device
echo "📱 Building for iOS device..."
xcodebuild build \
    -scheme SpeedManagerModule \
    -destination "generic/platform=iOS" \
    -configuration Release \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

# Build for iOS Simulator
echo "🖥️ Building for iOS simulator..."  
xcodebuild build \
    -scheme SpeedManagerModule \
    -destination "generic/platform=iOS Simulator" \
    -configuration Release \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES

echo "🔍 Checking build outputs..."
find .build -name "*SpeedManagerModule*" -type f 2>/dev/null | head -10 || echo "No .build found"
find .swiftpm -name "*SpeedManagerModule*" -type f 2>/dev/null | head -10 || echo "No .swiftpm found"

echo "✅ Build process completed. Check outputs above."