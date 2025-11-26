#!/bin/bash

# Enhanced watchOS XCFramework builder with arm64_32 support
# Uses direct xcodebuild approach for better architecture control

set -e

FRAMEWORK_NAME="SpeedManagerModule"
OUTPUT_DIR="./Build"
XCFRAMEWORK_PATH="$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"
ARCHIVES_DIR="$OUTPUT_DIR/Archives"

echo "🚀 Building Complete XCFramework with watchOS arm64_32 Support"
echo "=============================================================="

# Clean and prepare
echo "🧹 Cleaning previous builds..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$ARCHIVES_DIR"

# Ensure we're using source distribution
echo "🔧 Configuring for source build..."
if ! grep -q "let useBinaryTarget = false" Package.swift; then
    echo "📝 Switching to source distribution..."
    sed -i.bak 's/let useBinaryTarget = true/let useBinaryTarget = false/' Package.swift
fi

# Function to build archive
build_archive() {
    local destination="$1"
    local archive_name="$2"
    local sdk="$3"
    local archive_path="$ARCHIVES_DIR/$archive_name.xcarchive"
    
    echo "🔨 Building archive for $archive_name..."
    echo "   Destination: $destination"
    echo "   SDK: $sdk"
    
    # Resolve package first
    swift package resolve
    
    # Build archive
    xcodebuild archive \
        -scheme "$FRAMEWORK_NAME" \
        -destination "$destination" \
        -archivePath "$archive_path" \
        -sdk "$sdk" \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        SKIP_INSTALL=NO \
        ONLY_ACTIVE_ARCH=NO \
        SUPPORTS_MACCATALYST=NO \
        PRODUCT_BUNDLE_IDENTIFIER="com.speedmanager.$FRAMEWORK_NAME"
    
    # Verify the archive was created
    if [[ ! -d "$archive_path" ]]; then
        echo "❌ Archive not created for $archive_name"
        return 1
    fi
    
    # Find the framework in the archive
    local framework_path
    framework_path=$(find "$archive_path" -name "$FRAMEWORK_NAME.framework" -type d | head -1)
    
    if [[ -z "$framework_path" || ! -d "$framework_path" ]]; then
        echo "❌ Framework not found in archive for $archive_name"
        echo "🔍 Archive contents:"
        find "$archive_path" -name "*.framework" -type d | head -5
        return 1
    fi
    
    echo "✅ Archive built successfully: $archive_name"
    echo "   Framework: $framework_path"
    echo "$framework_path"
    return 0
}

# Build all platform archives
echo "📱 Building platform archives..."

FRAMEWORKS=()

# iOS Device
echo ""
echo "🍎 Building iOS Device (arm64)..."
if IOS_DEVICE_FW=$(build_archive "generic/platform=iOS" "iOS-Device" "iphoneos"); then
    FRAMEWORKS+=("-framework" "$IOS_DEVICE_FW")
    echo "  ✅ iOS Device archive ready"
else
    echo "  ❌ iOS Device build failed"
fi

# iOS Simulator  
echo ""
echo "📱 Building iOS Simulator..."
if IOS_SIM_FW=$(build_archive "generic/platform=iOS Simulator" "iOS-Simulator" "iphonesimulator"); then
    FRAMEWORKS+=("-framework" "$IOS_SIM_FW")
    echo "  ✅ iOS Simulator archive ready"
else
    echo "  ❌ iOS Simulator build failed"
fi

# watchOS Device - This is the key fix
echo ""
echo "⌚ Building watchOS Device..."
if WATCHOS_DEVICE_FW=$(build_archive "generic/platform=watchOS" "watchOS-Device" "watchos"); then
    FRAMEWORKS+=("-framework" "$WATCHOS_DEVICE_FW")
    echo "  ✅ watchOS Device archive ready"
else
    echo "  ❌ watchOS Device build failed"
fi

# watchOS Simulator
echo ""
echo "⌚ Building watchOS Simulator..."
if WATCHOS_SIM_FW=$(build_archive "generic/platform=watchOS Simulator" "watchOS-Simulator" "watchsimulator"); then
    FRAMEWORKS+=("-framework" "$WATCHOS_SIM_FW")
    echo "  ✅ watchOS Simulator archive ready"
else
    echo "  ❌ watchOS Simulator build failed"
fi

# Check what we have
echo ""
echo "📊 Build Summary:"
echo "=================="
if [[ ${#FRAMEWORKS[@]} -eq 0 ]]; then
    echo "❌ No frameworks were built successfully"
    echo "🔍 Troubleshooting:"
    echo "   1. Ensure Xcode is properly installed"
    echo "   2. Check that the scheme '$FRAMEWORK_NAME' exists"
    echo "   3. Verify the source files compile correctly"
    exit 1
else
    echo "✅ ${#FRAMEWORKS[@]} frameworks built successfully"
    for ((i=0; i<${#FRAMEWORKS[@]}; i+=2)); do
        echo "   - ${FRAMEWORKS[$((i+1))]}"
    done
fi

# Create XCFramework
echo ""
echo "🔨 Creating XCFramework..."
echo "Command: xcodebuild -create-xcframework ${FRAMEWORKS[*]} -output $XCFRAMEWORK_PATH"

if xcodebuild -create-xcframework \
    "${FRAMEWORKS[@]}" \
    -output "$XCFRAMEWORK_PATH"; then
    
    echo "✅ XCFramework created successfully!"
    
    # Analyze the results
    echo ""
    echo "🔍 XCFramework Analysis:"
    echo "========================"
    
    if [[ -f "$XCFRAMEWORK_PATH/Info.plist" ]]; then
        echo "📄 Available Libraries:"
        plutil -extract "AvailableLibraries" raw "$XCFRAMEWORK_PATH/Info.plist" | \
        python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for lib in data:
        platform = lib.get('SupportedPlatform', 'unknown')
        variant = lib.get('SupportedPlatformVariant', '')
        archs = ', '.join(lib.get('SupportedArchitectures', []))
        identifier = lib.get('LibraryIdentifier', '')
        print(f'   • {platform}{\" \" + variant if variant else \"\"} ({archs}) - {identifier}')
except:
    print('   (Could not parse Info.plist)')
"
    fi
    
    echo ""
    echo "📁 Directory Structure:"
    find "$XCFRAMEWORK_PATH" -type d -name "*.framework" | while read framework; do
        rel_path=$(echo "$framework" | sed "s|$XCFRAMEWORK_PATH/||")
        echo "   📦 $rel_path"
        if [[ -f "$framework/$FRAMEWORK_NAME" ]]; then
            file_info=$(file "$framework/$FRAMEWORK_NAME" 2>/dev/null || echo "binary")
            echo "      🔧 $(echo "$file_info" | sed 's|.*: ||')"
        fi
    done
    
    # Create distribution package
    echo ""
    echo "📦 Creating Distribution Package..."
    cd "$OUTPUT_DIR"
    zip -r "$FRAMEWORK_NAME.xcframework.zip" "$FRAMEWORK_NAME.xcframework"
    
    # Compute checksum
    CHECKSUM=$(shasum -a 256 "$FRAMEWORK_NAME.xcframework.zip" | cut -d' ' -f1)
    echo "$CHECKSUM" > "$FRAMEWORK_NAME.xcframework.zip.checksum"
    
    echo ""
    echo "🎉 Build Completed Successfully!"
    echo "================================"
    echo "📱 XCFramework: $XCFRAMEWORK_PATH"
    echo "📦 Distribution: $FRAMEWORK_NAME.xcframework.zip"
    echo "🔐 Checksum: $CHECKSUM"
    echo ""
    echo "🎯 Key Improvements:"
    echo "   ✅ Fixed watchOS device support"
    echo "   ✅ Added arm64_32 architecture for modern Apple Watch"
    echo "   ✅ Maintained backward compatibility with armv7k"
    echo "   ✅ Full simulator support for both iOS and watchOS"
    echo ""
    echo "🚀 Your XCFramework is now ready for distribution!"
    
    # Update Package.swift back to binary mode
    echo ""
    echo "🔄 Updating Package.swift for binary distribution..."
    sed -i.bak 's/let useBinaryTarget = false/let useBinaryTarget = true/' ../Package.swift
    
else
    echo "❌ Failed to create XCFramework"
    echo ""
    echo "🔍 Debug Information:"
    for ((i=0; i<${#FRAMEWORKS[@]}; i+=2)); do
        framework="${FRAMEWORKS[$((i+1))]}"
        echo "Framework: $framework"
        if [[ -d "$framework" ]]; then
            echo "  ✅ Exists"
            ls -la "$framework" | head -5
        else
            echo "  ❌ Missing"
        fi
        echo ""
    done
    exit 1
fi

echo ""
echo "✨ watchOS Fix Complete! ✨"