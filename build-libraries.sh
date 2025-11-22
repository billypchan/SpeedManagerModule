#!/bin/bash

set -e

FRAMEWORK_NAME="SpeedManagerModule"
BUILD_DIR="./Build"
XCFRAMEWORK_PATH="$BUILD_DIR/$FRAMEWORK_NAME.xcframework"

echo "🚀 Creating minimal working XCFramework for $FRAMEWORK_NAME"
echo "========================================================"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "📱 Building library for multiple targets..."

# Build for iOS Device
echo "  📱 iOS Device (arm64)..."
swift build -c release --triple arm64-apple-ios15.0 --build-path "$BUILD_DIR/ios-device"

# Build for iOS Simulator  
echo "  📱 iOS Simulator (arm64, x86_64)..."
swift build -c release --triple arm64-apple-ios15.0-simulator --build-path "$BUILD_DIR/ios-simulator-arm64"
swift build -c release --triple x86_64-apple-ios15.0-simulator --build-path "$BUILD_DIR/ios-simulator-x86_64"

# Build for macOS
echo "  💻 macOS (arm64, x86_64)..."
swift build -c release --triple arm64-apple-macos12.0 --build-path "$BUILD_DIR/macos-arm64"
swift build -c release --triple x86_64-apple-macos12.0 --build-path "$BUILD_DIR/macos-x86_64"

echo "📦 Checking build outputs..."
find "$BUILD_DIR" -name "lib$FRAMEWORK_NAME.*" -type f | head -10

echo "✅ Library builds completed!"
echo "💡 Note: Full XCFramework creation from SPM libraries requires additional framework wrapping"
echo "🎯 For distribution, consider using source distribution instead:"
echo "   ./build-source-distribution.sh"

echo ""
echo "📁 Build artifacts located in: $BUILD_DIR/"