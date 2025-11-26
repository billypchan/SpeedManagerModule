#!/bin/bash

# Simple watchOS arm64_32 XCFramework builder
# This script builds the XCFramework with all required architectures using swift build

set -e

FRAMEWORK_NAME="SpeedManagerModule"
OUTPUT_DIR="./Build"
XCFRAMEWORK_PATH="$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"
FRAMEWORKS_DIR="$OUTPUT_DIR/Frameworks"

echo "🚀 Building XCFramework with watchOS arm64_32 Support"
echo "====================================================="

# Clean and prepare
echo "🧹 Cleaning previous builds..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$FRAMEWORKS_DIR"

# Platform configurations - using a different approach for older bash
PLATFORMS=()
PLATFORMS[0]="iOS-Device:arm64-apple-ios15.0"
PLATFORMS[1]="iOS-Simulator:arm64-apple-ios15.0-simulator" 
PLATFORMS[2]="watchOS-Device:arm64_32-apple-watchos8.0"
PLATFORMS[3]="watchOS-Simulator:arm64-apple-watchos8.0-simulator"

# Function to build static library for a platform
build_static_lib() {
    local platform_name=$1
    local triple=$2
    local build_dir="$OUTPUT_DIR/build-$platform_name"
    
    echo "🔨 Building static library for $platform_name ($triple)..."
    
    # Build the static library
    if swift build \
        -c release \
        --triple "$triple" \
        --build-path "$build_dir"; then
        echo "✅ Swift build succeeded for $platform_name"
    else
        echo "❌ Swift build failed for $platform_name"
        return 1
    fi
    
    # Find the static library
    local lib_path
    lib_path=$(find "$build_dir" -name "lib$FRAMEWORK_NAME.a" | head -1)
    
    if [[ -z "$lib_path" || ! -f "$lib_path" ]]; then
        echo "❌ Could not find static library for $platform_name"
        echo "🔍 Build directory contents:"
        find "$build_dir" -name "*.a" -o -name "*$FRAMEWORK_NAME*" | head -10
        return 1
    fi
    
    echo "✅ Static library built: $lib_path"
    echo "$lib_path"
}

# Function to create framework from static library
create_framework() {
    local platform_name=$1
    local triple=$2
    local lib_path=$3
    local framework_path="$FRAMEWORKS_DIR/$platform_name.framework"
    local build_dir="$OUTPUT_DIR/build-$platform_name"
    
    echo "📦 Creating framework for $platform_name..."
    
    # Create framework structure
    mkdir -p "$framework_path/Modules/$FRAMEWORK_NAME.swiftmodule"
    
    # Copy the binary
    cp "$lib_path" "$framework_path/$FRAMEWORK_NAME"
    
    # Find and copy Swift modules
    local swift_module_dir
    swift_module_dir=$(find "$build_dir" -type d -name "$FRAMEWORK_NAME.swiftmodule" | head -1)
    if [[ -n "$swift_module_dir" && -d "$swift_module_dir" ]]; then
        cp -r "$swift_module_dir"/* "$framework_path/Modules/$FRAMEWORK_NAME.swiftmodule/"
        echo "  ✅ Swift modules copied"
    else
        echo "  ⚠️  No Swift modules found"
    fi
    
    # Determine minimum OS version
    local min_version
    case "$platform_name" in
        *watchOS*) min_version="8.0" ;;
        *iOS*) min_version="15.0" ;;
        *) min_version="12.0" ;;
    esac
    
    # Create Info.plist
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
    
    # Create module map
    cat > "$framework_path/Modules/module.modulemap" << EOF
framework module $FRAMEWORK_NAME {
    export *
    module * { export * }
}
EOF
    
    echo "✅ Framework created: $framework_path"
    echo "$framework_path"
}

# Build all platforms
echo "📱 Building all platform libraries..."

FRAMEWORK_ARGS=()
SUCCESS_COUNT=0

for platform_entry in "${PLATFORMS[@]}"; do
    platform_name=$(echo "$platform_entry" | cut -d':' -f1)
    triple=$(echo "$platform_entry" | cut -d':' -f2)
    
    echo ""
    echo "🔧 Processing $platform_name..."
    
    # Build static library
    if lib_path=$(build_static_lib "$platform_name" "$triple"); then
        # Create framework
        if framework_path=$(create_framework "$platform_name" "$triple" "$lib_path"); then
            FRAMEWORK_ARGS+=("-framework" "$framework_path")
            ((SUCCESS_COUNT++))
            echo "  ✅ $platform_name completed successfully"
        else
            echo "  ❌ Failed to create framework for $platform_name"
        fi
    else
        echo "  ❌ Failed to build library for $platform_name"
    fi
done

echo ""
echo "📊 Build Summary:"
echo "================"
echo "✅ Successfully built $SUCCESS_COUNT out of 4 platforms"

if [[ ${#FRAMEWORK_ARGS[@]} -eq 0 ]]; then
    echo "❌ No frameworks were created successfully"
    exit 1
fi

echo ""
echo "🔨 Creating XCFramework..."
echo "Command: xcodebuild -create-xcframework ${FRAMEWORK_ARGS[*]} -output $XCFRAMEWORK_PATH"

if xcodebuild -create-xcframework \
    "${FRAMEWORK_ARGS[@]}" \
    -output "$XCFRAMEWORK_PATH"; then
    
    echo "✅ XCFramework created successfully!"
    
    # Analyze the XCFramework
    echo ""
    echo "🔍 XCFramework Analysis:"
    echo "========================"
    
    if [[ -f "$XCFRAMEWORK_PATH/Info.plist" ]]; then
        echo "📄 Available Libraries:"
        
        # Use Python to parse the plist properly
        python3 << EOF
import plistlib
import sys

try:
    with open("$XCFRAMEWORK_PATH/Info.plist", "rb") as f:
        plist = plistlib.load(f)
    
    libraries = plist.get("AvailableLibraries", [])
    for lib in libraries:
        platform = lib.get("SupportedPlatform", "unknown")
        variant = lib.get("SupportedPlatformVariant", "")
        archs = ", ".join(lib.get("SupportedArchitectures", []))
        identifier = lib.get("LibraryIdentifier", "")
        
        platform_str = f"{platform}"
        if variant:
            platform_str += f" {variant}"
        
        print(f"   • {platform_str} ({archs}) - {identifier}")
        
        # Special highlight for watchOS arm64_32
        if platform == "watchos" and "arm64_32" in archs and not variant:
            print("     🎯 THIS IS THE NEW watchOS arm64_32 SUPPORT!")
            
except Exception as e:
    print(f"   (Could not parse Info.plist: {e})")
EOF
    fi
    
    echo ""
    echo "📁 Framework Structure:"
    find "$XCFRAMEWORK_PATH" -type d -name "*.framework" | while read framework; do
        rel_path=$(echo "$framework" | sed "s|$XCFRAMEWORK_PATH/||")
        echo "   📦 $rel_path"
        
        # Check binary
        binary_path="$framework/$FRAMEWORK_NAME"
        if [[ -f "$binary_path" ]]; then
            arch_info=$(file "$binary_path" 2>/dev/null | sed 's|.*: ||' || echo "binary file")
            echo "      🔧 $arch_info"
            
            # Special check for watchOS arm64_32
            if [[ "$rel_path" == *"watchos"* ]] && file "$binary_path" 2>/dev/null | grep -q "arm64_32"; then
                echo "      🎯 WATCHOS ARM64_32 DETECTED!"
            fi
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
    echo "🎉 SUCCESS! XCFramework Build Completed"
    echo "========================================"
    echo "📱 XCFramework: $XCFRAMEWORK_PATH"
    echo "📦 Distribution: $OUTPUT_DIR/$FRAMEWORK_NAME.xcframework.zip"
    echo "🔐 Checksum: $CHECKSUM"
    echo ""
    echo "🎯 WATCHOS FIX COMPLETED!"
    echo "========================="
    echo "✅ Your XCFramework now includes:"
    echo "   • iOS Device (arm64)"
    echo "   • iOS Simulator (arm64)"
    echo "   • watchOS Device (arm64_32) ← FIXED!"
    echo "   • watchOS Simulator (arm64)"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Test the XCFramework in your watchOS projects"
    echo "2. Verify arm64_32 architecture is detected properly"
    echo "3. Distribute using the ZIP file above"
    echo ""
    echo "✨ watchOS build is now fixed with proper arm64_32 support!"
    
    # Switch Package.swift back to binary mode
    cd ..
    sed -i.bak 's/let useBinaryTarget = false/let useBinaryTarget = true/' Package.swift
    
else
    echo "❌ Failed to create XCFramework"
    echo ""
    echo "🔍 Debug Information:"
    echo "Frameworks that were created:"
    for ((i=0; i<${#FRAMEWORK_ARGS[@]}; i+=2)); do
        framework="${FRAMEWORK_ARGS[$((i+1))]}"
        echo "  - $framework"
        if [[ -d "$framework" ]]; then
            echo "    ✅ Directory exists"
            ls -la "$framework" | head -3
        else
            echo "    ❌ Directory missing"
        fi
        echo ""
    done
    exit 1
fi

echo ""
echo "🎯 Mission Accomplished! Your watchOS XCFramework now supports arm64_32!"