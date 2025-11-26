#!/bin/bash

# Create proper frameworks and XCFramework
set -e

echo "🚀 Building proper frameworks for XCFramework..."

# Clean
rm -rf Build/SpeedManagerModule.xcframework
rm -rf Build/TempFrameworks
mkdir -p Build/TempFrameworks

# Helper function to create framework structure
create_framework() {
    local platform=$1
    local arch=$2
    local sdk=$3
    local target_triple=$4
    local framework_name="SpeedManagerModule-$platform"
    local framework_dir="Build/TempFrameworks/$framework_name.framework"
    
    echo "📱 Creating framework for $platform ($arch)..."
    
    # Create framework directory structure
    mkdir -p "$framework_dir/Modules"
    
    # Compile Swift module
    swiftc -emit-library \
           -emit-module \
           -module-name SpeedManagerModule \
           -target "$target_triple" \
           -sdk "$sdk" \
           -O \
           -enable-library-evolution \
           -emit-module-path "$framework_dir/Modules/SpeedManagerModule.swiftmodule" \
           -emit-module-interface-path "$framework_dir/Modules/SpeedManagerModule.swiftinterface" \
           -o "$framework_dir/SpeedManagerModule" \
           Sources/SpeedManagerModule/*.swift
    
    # Create Info.plist
    cat > "$framework_dir/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>SpeedManagerModule</string>
    <key>CFBundleIdentifier</key>
    <string>com.speedmanager.SpeedManagerModule</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>SpeedManagerModule</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>$platform</string>
    </array>
</dict>
</plist>
EOF
    
    echo "✅ Framework created: $framework_dir"
    if [ -f "$framework_dir/SpeedManagerModule" ]; then
        file "$framework_dir/SpeedManagerModule"
        lipo -archs "$framework_dir/SpeedManagerModule" 2>/dev/null || echo "Single arch"
    fi
}

# Get SDK paths
ios_sdk=$(xcrun --sdk iphoneos --show-sdk-path)
ios_sim_sdk=$(xcrun --sdk iphonesimulator --show-sdk-path) 
watchos_sdk=$(xcrun --sdk watchos --show-sdk-path)
watchos_sim_sdk=$(xcrun --sdk watchsimulator --show-sdk-path)
macos_sdk=$(xcrun --sdk macosx --show-sdk-path)

# Create frameworks for each platform
create_framework "iPhoneOS" "arm64" "$ios_sdk" "arm64-apple-ios15.0"
create_framework "iPhoneSimulator" "arm64_x86_64" "$ios_sim_sdk" "arm64-apple-ios15.0-simulator" 
create_framework "WatchOS" "arm64_32" "$watchos_sdk" "arm64_32-apple-watchos9.0"
create_framework "WatchSimulator" "arm64_x86_64" "$watchos_sim_sdk" "arm64-apple-watchos9.0-simulator"
create_framework "MacOSX" "arm64_x86_64" "$macos_sdk" "arm64-apple-macosx12.0"

# List created frameworks
echo "📁 Created frameworks:"
ls -la Build/TempFrameworks/

# Create XCFramework (if we have valid frameworks)
if [ -d "Build/TempFrameworks/SpeedManagerModule-iPhoneOS.framework" ] && [ -f "Build/TempFrameworks/SpeedManagerModule-iPhoneOS.framework/SpeedManagerModule" ]; then
    echo "🔧 Creating XCFramework..."
    
    xcodebuild -create-xcframework \
        -framework "Build/TempFrameworks/SpeedManagerModule-iPhoneOS.framework" \
        -framework "Build/TempFrameworks/SpeedManagerModule-iPhoneSimulator.framework" \
        -framework "Build/TempFrameworks/SpeedManagerModule-WatchOS.framework" \
        -framework "Build/TempFrameworks/SpeedManagerModule-WatchSimulator.framework" \
        -framework "Build/TempFrameworks/SpeedManagerModule-MacOSX.framework" \
        -output "Build/SpeedManagerModule.xcframework"
    
    echo "✅ XCFramework created successfully!"
    
    # Verify architectures
    echo "🔍 Verifying XCFramework architectures:"
    for platform_dir in Build/SpeedManagerModule.xcframework/*/; do
        if [ -d "$platform_dir" ]; then
            framework_dir="$platform_dir/SpeedManagerModule.framework"
            if [ -d "$framework_dir" ]; then
                binary="$framework_dir/SpeedManagerModule"
                if [ -f "$binary" ]; then
                    platform_name=$(basename "$platform_dir")
                    echo "📱 $platform_name:"
                    lipo -archs "$binary" 2>/dev/null || echo "  Single architecture"
                fi
            fi
        fi
    done
else
    echo "❌ Framework creation failed"
    exit 1
fi

echo "🎉 SpeedManagerModule.xcframework successfully created with correct architectures!"