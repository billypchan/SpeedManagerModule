#!/bin/bash

set -e  # Exit on any error

echo "🚀 Starting simplified XCFramework build..."

# First, fix the missing Combine import
echo "🔧 Adding missing Combine import..."
if ! grep -q "import Combine" Sources/SpeedManagerModule/SpeedManager.swift; then
    sed -i '' '1i\
import Combine
' Sources/SpeedManagerModule/SpeedManager.swift
fi

# Build using swift build for different platforms
echo "🔨 Building static libraries..."

# Clean any previous builds
rm -rf .build
rm -rf Build
mkdir -p Build/Frameworks

# Build for iOS device (arm64)
echo "📱 Building for iOS (arm64)..."
swift build -c release \
    --target SpeedManagerModule \
    --destination .build/arm64-apple-ios.json \
    2>/dev/null || true

# Since direct cross-compilation might not work, let's use xcodebuild in a simpler way
echo "📦 Building using xcodebuild..."

# Create workspace for building
if [[ ! -f Package.resolved ]]; then
    swift package resolve
fi

# Generate Xcode project
swift package generate-xcodeproj

# Build for iOS
xcodebuild build \
    -project SpeedManagerModule.xcodeproj \
    -scheme SpeedManagerModule-Package \
    -configuration Release \
    -sdk iphoneos \
    -arch arm64 \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    BITCODE_GENERATION_MODE=bitcode

# Build for iOS Simulator  
xcodebuild build \
    -project SpeedManagerModule.xcodeproj \
    -scheme SpeedManagerModule-Package \
    -configuration Release \
    -sdk iphonesimulator \
    -arch x86_64 \
    -arch arm64 \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    BITCODE_GENERATION_MODE=bitcode

echo "🔍 Checking what was built..."
find . -name "*SpeedManagerModule*" -type f | grep -E "\.(a|dylib|framework)" | head -10

echo "✅ Build completed! Check the build output above."