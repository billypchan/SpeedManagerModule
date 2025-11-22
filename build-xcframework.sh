#!/bin/bash

# Build XCFramework for SpeedManagerModule with correct architectures
# This script creates frameworks for all platforms and combines them into an XCFramework

set -e

echo "🚀 Building XCFramework for SpeedManagerModule..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf Build/SpeedManagerModule.xcframework
rm -rf Build/Frameworks
mkdir -p Build/Frameworks

# Function to build framework for a platform
build_framework() {
    local platform=$1
    local sdk=$2
    local destination=$3
    local output_name=$4
    local archs=$5
    
    echo "📱 Building framework for $platform..."
    
    xcodebuild build \
        -scheme SpeedManagerModule \
        -destination "$destination" \
        -sdk $sdk \
        -configuration Release \
        -derivedDataPath "Build/DerivedData" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO \
        ARCHS="$archs" \
        ONLY_ACTIVE_ARCH=NO
    
    # Find and copy the built framework
    framework_path=$(find Build/DerivedData -name "SpeedManagerModule.framework" -path "*Release-$sdk*" | head -1)
    if [ -n "$framework_path" ]; then
        cp -R "$framework_path" "Build/Frameworks/SpeedManagerModule-$output_name.framework"
        echo "✅ Framework copied to Build/Frameworks/SpeedManagerModule-$output_name.framework"
    else
        echo "❌ Framework not found for $platform"
        return 1
    fi
}

# Build for iOS Device (arm64)
build_framework "iOS Device" "iphoneos" "generic/platform=iOS" "iOS" "arm64"

# Build for iOS Simulator (arm64 + x86_64)
build_framework "iOS Simulator" "iphonesimulator" "generic/platform=iOS Simulator" "iOS-Simulator" "arm64 x86_64"

# Build for watchOS Device (arm64_32 - the correct architecture for watchOS 9+)
build_framework "watchOS Device" "watchos" "generic/platform=watchOS" "watchOS" "arm64_32"

# Build for watchOS Simulator (arm64 + x86_64)
build_framework "watchOS Simulator" "watchsimulator" "generic/platform=watchOS Simulator" "watchOS-Simulator" "arm64 x86_64"

# Build for macOS (arm64 + x86_64)
build_framework "macOS" "macosx" "generic/platform=macOS" "macOS" "arm64 x86_64"

# Verify frameworks were created
echo "🔍 Verifying built frameworks..."
for framework in Build/Frameworks/*.framework; do
    if [ -d "$framework" ]; then
        binary="$framework/SpeedManagerModule"
        if [ -f "$binary" ]; then
            echo "📋 $(basename $framework):"
            file "$binary"
            lipo -archs "$binary" 2>/dev/null || echo "  Single architecture"
        fi
    fi
done

# Create XCFramework
echo "🔧 Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "Build/Frameworks/SpeedManagerModule-iOS.framework" \
    -framework "Build/Frameworks/SpeedManagerModule-iOS-Simulator.framework" \
    -framework "Build/Frameworks/SpeedManagerModule-watchOS.framework" \
    -framework "Build/Frameworks/SpeedManagerModule-watchOS-Simulator.framework" \
    -framework "Build/Frameworks/SpeedManagerModule-macOS.framework" \
    -output "Build/SpeedManagerModule.xcframework"

# Verify the XCFramework
echo "🔍 Verifying XCFramework architectures..."
for platform_dir in Build/SpeedManagerModule.xcframework/*/; do
    if [ -d "$platform_dir" ]; then
        framework_dir="$platform_dir/SpeedManagerModule.framework"
        if [ -d "$framework_dir" ]; then
            binary="$framework_dir/SpeedManagerModule"
            if [ -f "$binary" ]; then
                platform_name=$(basename "$platform_dir")
                echo "📱 $platform_name:"
                lipo -archs "$binary" 2>/dev/null || echo "  Single architecture"
                # Check if this is the watchOS device framework with correct architecture
                if [[ "$platform_name" == *"watchos"* ]] && [[ "$platform_name" != *"simulator"* ]]; then
                    archs=$(lipo -archs "$binary" 2>/dev/null)
                    if [[ "$archs" == *"arm64_32"* ]]; then
                        echo "  ✅ Correct watchOS arm64_32 architecture found!"
                    else
                        echo "  ⚠️  Expected arm64_32 for watchOS device, found: $archs"
                    fi
                fi
            fi
        fi
    fi
done

# Sign the XCFramework
echo "🔏 Signing XCFramework..."
codesign --sign "Chan Bill" --timestamp --force --deep Build/SpeedManagerModule.xcframework || echo "⚠️  Code signing failed (certificate not found), but XCFramework is still usable"

# Create ZIP for distribution
echo "📦 Creating distribution ZIP..."
cd Build
zip -r SpeedManagerModule.xcframework.zip SpeedManagerModule.xcframework
cd ..

echo "✅ XCFramework creation complete!"
echo "📊 Framework info:"
du -sh Build/SpeedManagerModule.xcframework 2>/dev/null || echo "Framework size calculation failed"
ls -lh Build/SpeedManagerModule.xcframework.zip 2>/dev/null || echo "ZIP not created"

echo ""
echo "🎉 SpeedManagerModule.xcframework has been recreated with correct architectures!"
echo "   - iOS Device: arm64"
echo "   - iOS Simulator: arm64, x86_64"  
echo "   - watchOS Device: arm64_32 (correct for watchOS 9+)"
echo "   - watchOS Simulator: arm64, x86_64"
echo "   - macOS: arm64, x86_64"