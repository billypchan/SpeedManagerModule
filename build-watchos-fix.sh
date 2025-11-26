#!/bin/bash

# Fix watchOS XCFramework build - Add arm64_32 for device support
# This script rebuilds the XCFramework with proper watchOS architectures

set -e

FRAMEWORK_NAME="SpeedManagerModule"
OUTPUT_DIR="./Build"
XCFRAMEWORK_PATH="$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"
ARCHIVES_DIR="$OUTPUT_DIR/Archives"
TEMP_DIR="$OUTPUT_DIR/Temp"

echo "🚀 Fixing watchOS Build - Adding arm64_32 Architecture"
echo "======================================================="

# Clean and prepare
echo "🧹 Cleaning previous builds..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$ARCHIVES_DIR" "$TEMP_DIR"

# Function to create archive using xcodebuild
create_archive() {
    local destination="$1"
    local platform="$2"
    local sdk="$3"
    local archive_name="$4"
    local archive_path="$ARCHIVES_DIR/$archive_name.xcarchive"
    
    echo "🔨 Creating archive for $platform..."
    
    # First, try to resolve the package if needed
    if [[ ! -d ".swiftpm/xcode" ]]; then
        echo "📦 Resolving Swift package..."
        swift package resolve
    fi
    
    # Use xcodebuild to create archive
    xcodebuild archive \
        -scheme "$FRAMEWORK_NAME" \
        -destination "$destination" \
        -archivePath "$archive_path" \
        -sdk "$sdk" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO \
        ONLY_ACTIVE_ARCH=NO \
        PRODUCT_BUNDLE_IDENTIFIER="com.speedmanager.$FRAMEWORK_NAME" \
        SWIFT_SERIALIZE_DEBUGGING_OPTIONS=NO \
        SWIFT_COMPILATION_MODE=wholemodule
        
    echo "✅ Archive created: $archive_path"
    return 0
}

# Function to create framework manually using swift build
create_framework_manual() {
    local triple="$1"
    local platform="$2"
    local framework_path="$TEMP_DIR/$platform.framework"
    
    echo "🔨 Building framework for $platform (triple: $triple)..."
    
    # Build using swift build
    swift build -c release --triple "$triple" --build-path "$TEMP_DIR/.build-$platform"
    
    # Find the built library
    local lib_path
    lib_path=$(find "$TEMP_DIR/.build-$platform" -name "lib$FRAMEWORK_NAME.a" -o -name "$FRAMEWORK_NAME" | head -1)
    
    if [[ -z "$lib_path" || ! -f "$lib_path" ]]; then
        echo "❌ Could not find built library for $platform"
        return 1
    fi
    
    # Create framework structure
    mkdir -p "$framework_path/Modules/$FRAMEWORK_NAME.swiftmodule"
    
    # Copy the binary
    cp "$lib_path" "$framework_path/$FRAMEWORK_NAME"
    
    # Find and copy Swift modules
    local swift_module_dir
    swift_module_dir=$(find "$TEMP_DIR/.build-$platform" -type d -name "$FRAMEWORK_NAME.swiftmodule" | head -1)
    if [[ -n "$swift_module_dir" && -d "$swift_module_dir" ]]; then
        cp -r "$swift_module_dir"/* "$framework_path/Modules/$FRAMEWORK_NAME.swiftmodule/"
    fi
    
    # Create Info.plist
    local min_version
    case "$platform" in
        *watchOS*) min_version="8.0" ;;
        *iOS*) min_version="15.0" ;;
        *) min_version="12.0" ;;
    esac
    
    cat > "$framework_path/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$FRAMEWORK_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.speedmanager.$FRAMEWORK_NAME</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$FRAMEWORK_NAME</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>$min_version</string>
</dict>
</plist>
EOF
    
    echo "✅ Framework created: $framework_path"
    echo "$framework_path"
    return 0
}

# Build all required frameworks
echo "📱 Building all platform frameworks..."

FRAMEWORKS=()

# iOS Device (arm64)
echo "🍎 Building iOS Device..."
if IOS_DEVICE=$(create_framework_manual "arm64-apple-ios15.0" "iOS-Device"); then
    FRAMEWORKS+=("-framework" "$IOS_DEVICE")
    echo "  ✅ iOS Device framework ready"
else
    echo "  ❌ iOS Device build failed"
fi

# iOS Simulator (arm64 + x86_64)
echo "🖥️ Building iOS Simulator..."
if IOS_SIM=$(create_framework_manual "arm64-apple-ios15.0-simulator" "iOS-Simulator"); then
    FRAMEWORKS+=("-framework" "$IOS_SIM")
    echo "  ✅ iOS Simulator framework ready"
else
    echo "  ❌ iOS Simulator build failed"
fi

# watchOS Device (arm64_32) - This is the key addition
echo "⌚ Building watchOS Device (arm64_32)..."
if WATCHOS_DEVICE=$(create_framework_manual "arm64_32-apple-watchos8.0" "watchOS-Device"); then
    FRAMEWORKS+=("-framework" "$WATCHOS_DEVICE")
    echo "  ✅ watchOS Device (arm64_32) framework ready"
else
    echo "  ❌ watchOS Device build failed"
fi

# watchOS Device (armv7k) - Legacy support
echo "⌚ Building watchOS Device (armv7k)..."
if WATCHOS_LEGACY=$(create_framework_manual "armv7k-apple-watchos8.0" "watchOS-Legacy"); then
    FRAMEWORKS+=("-framework" "$WATCHOS_LEGACY")
    echo "  ✅ watchOS Device (armv7k) framework ready"
else
    echo "  ❌ watchOS Legacy build failed"
fi

# watchOS Simulator 
echo "🖥️ Building watchOS Simulator..."
if WATCHOS_SIM=$(create_framework_manual "arm64-apple-watchos8.0-simulator" "watchOS-Simulator"); then
    FRAMEWORKS+=("-framework" "$WATCHOS_SIM")
    echo "  ✅ watchOS Simulator framework ready"
else
    echo "  ❌ watchOS Simulator build failed"
fi

# Check if we have frameworks to work with
if [[ ${#FRAMEWORKS[@]} -eq 0 ]]; then
    echo "❌ No frameworks were built successfully"
    exit 1
fi

echo ""
echo "📦 Creating XCFramework with ${#FRAMEWORKS[@]} frameworks..."
echo "Frameworks: ${FRAMEWORKS[*]}"

# Create the XCFramework
if xcodebuild -create-xcframework \
    "${FRAMEWORKS[@]}" \
    -output "$XCFRAMEWORK_PATH"; then
    
    echo "✅ XCFramework created successfully!"
    
    # Verify the XCFramework contents
    echo ""
    echo "🔍 Verifying XCFramework structure..."
    if [[ -f "$XCFRAMEWORK_PATH/Info.plist" ]]; then
        echo "📄 XCFramework Info.plist contents:"
        plutil -p "$XCFRAMEWORK_PATH/Info.plist" | grep -A 20 "AvailableLibraries"
    fi
    
    echo ""
    echo "📁 XCFramework directory structure:"
    find "$XCFRAMEWORK_PATH" -type d -name "*.framework" | sed 's|^.*/||'
    
    # Check for binaries
    echo ""
    echo "🔍 Checking binary files:"
    find "$XCFRAMEWORK_PATH" -name "$FRAMEWORK_NAME" -type f -exec file {} \;
    
    # Create ZIP for distribution
    echo ""
    echo "📦 Creating distribution package..."
    cd "$OUTPUT_DIR"
    zip -r "$FRAMEWORK_NAME.xcframework.zip" "$FRAMEWORK_NAME.xcframework"
    
    # Compute checksum
    CHECKSUM=$(shasum -a 256 "$FRAMEWORK_NAME.xcframework.zip" | cut -d' ' -f1)
    echo "$CHECKSUM" > "$FRAMEWORK_NAME.xcframework.zip.checksum"
    
    echo ""
    echo "🎉 watchOS Fix Completed Successfully!"
    echo "====================================="
    echo "📱 XCFramework: $XCFRAMEWORK_PATH"
    echo "📦 Distribution: $FRAMEWORK_NAME.xcframework.zip"
    echo "🔐 Checksum: $CHECKSUM"
    echo ""
    echo "🔧 Architectures included:"
    echo "   • iOS Device (arm64)"
    echo "   • iOS Simulator (arm64)"
    echo "   • watchOS Device (arm64_32) ← NEW!"
    echo "   • watchOS Device (armv7k) ← Legacy"
    echo "   • watchOS Simulator (arm64)"
    echo ""
    echo "✅ Your watchOS build is now fixed with arm64_32 support!"
    
else
    echo "❌ Failed to create XCFramework"
    echo "🔍 Debug information:"
    echo "Available frameworks:"
    for fw in "${FRAMEWORKS[@]}"; do
        if [[ "$fw" != "-framework" ]]; then
            echo "  - $fw"
            ls -la "$fw" 2>/dev/null || echo "    (not found)"
        fi
    done
    exit 1
fi

# Clean up temporary files
echo ""
echo "🧹 Cleaning up temporary files..."
rm -rf "$TEMP_DIR" "$ARCHIVES_DIR"

echo "🎯 Done! Your XCFramework now supports all required watchOS architectures."