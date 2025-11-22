#!/bin/bash

set -e

FRAMEWORK_NAME="SpeedManagerModule"
BUILD_DIR="./Build"
ARCHIVES_DIR="$BUILD_DIR/Archives"
XCFRAMEWORK_PATH="$BUILD_DIR/$FRAMEWORK_NAME.xcframework"
DERIVED_DATA_PATH="$BUILD_DIR/DerivedData"

echo "🚀 Building Real XCFramework with Binaries for $FRAMEWORK_NAME"
echo "=============================================================="

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$BUILD_DIR"
mkdir -p "$ARCHIVES_DIR"
mkdir -p "$DERIVED_DATA_PATH"

# Function to build framework for a platform
build_framework() {
    local platform=$1
    local sdk=$2
    local destination=$3
    local archive_path="$ARCHIVES_DIR/${platform}.xcarchive"
    
    echo "📱 Building for $platform ($sdk)..."
    
    xcodebuild archive \
        -scheme "$FRAMEWORK_NAME" \
        -destination "$destination" \
        -archivePath "$archive_path" \
        -sdk "$sdk" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO \
        PRODUCT_BUNDLE_IDENTIFIER="com.speedmanager.$FRAMEWORK_NAME" \
        OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface"
        
    # Check if framework was created
    local framework_path="$archive_path/Products/Library/Frameworks/$FRAMEWORK_NAME.framework"
    if [[ -d "$framework_path" ]]; then
        echo "  ✅ Framework created at: $framework_path"
        return 0
    else
        echo "  ❌ Framework not found at expected location"
        echo "  🔍 Searching for framework in archive..."
        find "$archive_path" -name "*.framework" -type d | head -5
        return 1
    fi
}

# Try to use .swiftpm/xcode project if it exists, otherwise create temporary project
if [[ ! -d ".swiftpm/xcode" ]]; then
    echo "📦 Opening package in Xcode to generate project files..."
    # This will create .swiftpm/xcode directory
    xed .
    
    echo "⏳ Waiting for Xcode project generation..."
    sleep 5
    
    # Wait for the project to be generated
    timeout=30
    while [[ ! -d ".swiftpm/xcode" && $timeout -gt 0 ]]; do
        sleep 1
        ((timeout--))
    done
    
    if [[ ! -d ".swiftpm/xcode" ]]; then
        echo "❌ Xcode project generation failed"
        echo "💡 Try opening the package in Xcode first, then run this script"
        exit 1
    fi
fi

echo "✅ Using Xcode project at .swiftpm/xcode"

# Set working directory to .swiftpm/xcode
cd .swiftpm/xcode

# Build for iOS Device
build_framework "iOS" "iphoneos" "generic/platform=iOS"

# Build for iOS Simulator
build_framework "iOS-Simulator" "iphonesimulator" "generic/platform=iOS Simulator"

# Build for macOS
build_framework "macOS" "macosx" "generic/platform=macOS"

# Go back to root directory
cd ../..

echo "📦 Creating XCFramework from built frameworks..."

# Collect framework paths
ios_framework="$ARCHIVES_DIR/iOS.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework"
ios_sim_framework="$ARCHIVES_DIR/iOS-Simulator.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework"
macos_framework="$ARCHIVES_DIR/macOS.xcarchive/Products/Library/Frameworks/$FRAMEWORK_NAME.framework"

# Check which frameworks were successfully built
frameworks=()
if [[ -d "$ios_framework" ]]; then
    frameworks+=("-framework" "$ios_framework")
    echo "✅ iOS framework found"
else
    echo "⚠️  iOS framework missing"
fi

if [[ -d "$ios_sim_framework" ]]; then
    frameworks+=("-framework" "$ios_sim_framework")
    echo "✅ iOS Simulator framework found"
else
    echo "⚠️  iOS Simulator framework missing"
fi

if [[ -d "$macos_framework" ]]; then
    frameworks+=("-framework" "$macos_framework")
    echo "✅ macOS framework found"
else
    echo "⚠️  macOS framework missing"
fi

if [[ ${#frameworks[@]} -eq 0 ]]; then
    echo "❌ No frameworks were built successfully"
    echo "🔍 Let's check what was actually created..."
    find "$ARCHIVES_DIR" -name "*.framework" -type d
    exit 1
fi

# Create XCFramework
echo "🔨 Creating XCFramework with ${#frameworks[@]} frameworks..."
xcodebuild -create-xcframework \
    "${frameworks[@]}" \
    -output "$XCFRAMEWORK_PATH"

if [[ -d "$XCFRAMEWORK_PATH" ]]; then
    echo "✅ XCFramework created successfully!"
    
    # Show contents
    echo "📁 XCFramework contents:"
    find "$XCFRAMEWORK_PATH" -type f | head -10
    
    # Check for actual binaries
    echo ""
    echo "🔍 Checking for binary files..."
    find "$XCFRAMEWORK_PATH" -name "$FRAMEWORK_NAME" -type f -exec file {} \;
    
    # Create ZIP
    echo "📦 Creating ZIP archive..."
    cd "$BUILD_DIR"
    zip -r "$FRAMEWORK_NAME.xcframework.zip" "$FRAMEWORK_NAME.xcframework"
    cd ..
    
    echo ""
    echo "🎉 Success! XCFramework with binaries created:"
    echo "   📁 $XCFRAMEWORK_PATH"
    echo "   📦 $BUILD_DIR/$FRAMEWORK_NAME.xcframework.zip"
    echo ""
    echo "📊 Size information:"
    du -sh "$XCFRAMEWORK_PATH"
    du -sh "$BUILD_DIR/$FRAMEWORK_NAME.xcframework.zip"
    
else
    echo "❌ XCFramework creation failed"
    exit 1
fi