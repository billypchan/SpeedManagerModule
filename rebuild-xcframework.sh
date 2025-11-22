#!/bin/bash

set -e

FRAMEWORK_NAME="SpeedManagerModule"
SCHEME_NAME="SpeedManagerModule"
BUILD_DIR="./Build"
ARCHIVES_DIR="$BUILD_DIR/Archives"
XCFRAMEWORK_PATH="$BUILD_DIR/$FRAMEWORK_NAME.xcframework"

echo "🚀 Rebuilding XCFramework for $FRAMEWORK_NAME"
echo "=============================================="

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$BUILD_DIR"
mkdir -p "$ARCHIVES_DIR"

# Build for iOS Device
echo "📱 Building for iOS Device (arm64)..."
xcodebuild archive \
    -scheme "$SCHEME_NAME" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVES_DIR/iOS.xcarchive" \
    -sdk iphoneos \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO

# Build for iOS Simulator
echo "📱 Building for iOS Simulator (arm64, x86_64)..."
xcodebuild archive \
    -scheme "$SCHEME_NAME" \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "$ARCHIVES_DIR/iOS-Simulator.xcarchive" \
    -sdk iphonesimulator \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO

# Build for macOS
echo "💻 Building for macOS (arm64, x86_64)..."
xcodebuild archive \
    -scheme "$SCHEME_NAME" \
    -destination "generic/platform=macOS" \
    -archivePath "$ARCHIVES_DIR/macOS.xcarchive" \
    -sdk macosx \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    SKIP_INSTALL=NO

# Create XCFramework
echo "📦 Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "$ARCHIVES_DIR/iOS.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
    -framework "$ARCHIVES_DIR/iOS-Simulator.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
    -framework "$ARCHIVES_DIR/macOS.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework" \
    -output "$XCFRAMEWORK_PATH"

echo "✅ XCFramework created successfully!"
echo "📁 Location: $XCFRAMEWORK_PATH"

# Create ZIP archive
echo "📦 Creating ZIP archive..."
cd "$BUILD_DIR"
zip -r "$FRAMEWORK_NAME.xcframework.zip" "$FRAMEWORK_NAME.xcframework"
cd ..

echo "🎉 Build complete!"
echo "📦 Files created:"
echo "   - $XCFRAMEWORK_PATH"
echo "   - $BUILD_DIR/$FRAMEWORK_NAME.xcframework.zip"