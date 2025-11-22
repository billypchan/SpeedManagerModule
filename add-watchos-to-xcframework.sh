#!/bin/bash

set -e

echo "🚀 Adding watchOS support to XCFramework..."

# Find the DerivedData path
DERIVED_DATA=$(find ~/Library/Developer/Xcode/DerivedData -name "SpeedManagerModule-*" -type d | head -1)
echo "📁 Using DerivedData: $DERIVED_DATA"

# Backup current XCFramework
echo "💾 Backing up current XCFramework..."
if [[ -d "Build/SpeedManagerModule.xcframework.backup" ]]; then
    rm -rf "Build/SpeedManagerModule.xcframework.backup"
fi
cp -r "Build/SpeedManagerModule.xcframework" "Build/SpeedManagerModule.xcframework.backup"

# Create watchOS Device framework structure
echo "⌚ Creating watchOS Device framework..."
WATCHOS_DIR="Build/Temp/watchos-arm64_armv7k_arm64_32"
mkdir -p "$WATCHOS_DIR/SpeedManagerModule.framework/Modules/SpeedManagerModule.swiftmodule"

# Copy watchOS binary
WATCHOS_BINARY=$(find "$DERIVED_DATA" -path "*Release-watchos*" -name "SpeedManagerModule.o" | head -1)
if [[ -n "$WATCHOS_BINARY" && -f "$WATCHOS_BINARY" ]]; then
    cp "$WATCHOS_BINARY" "$WATCHOS_DIR/SpeedManagerModule.framework/SpeedManagerModule"
    echo "  ✅ watchOS binary copied"
else
    echo "  ❌ watchOS binary not found"
    exit 1
fi

# Copy watchOS Swift modules
WATCHOS_MODULE_DIR=$(find "$DERIVED_DATA" -path "*Release-watchos*" -name "SpeedManagerModule.swiftmodule" -type d | head -1)
if [[ -n "$WATCHOS_MODULE_DIR" && -d "$WATCHOS_MODULE_DIR" ]]; then
    cp -r "$WATCHOS_MODULE_DIR"/* "$WATCHOS_DIR/SpeedManagerModule.framework/Modules/SpeedManagerModule.swiftmodule/"
    echo "  ✅ watchOS Swift modules copied"
fi

# Create watchOS Simulator framework structure
echo "🖥️ Creating watchOS Simulator framework..."
WATCHOS_SIM_DIR="Build/Temp/watchos-arm64_x86_64-simulator"
mkdir -p "$WATCHOS_SIM_DIR/SpeedManagerModule.framework/Modules/SpeedManagerModule.swiftmodule"

# Copy watchOS Simulator binary
WATCHOS_SIM_BINARY=$(find "$DERIVED_DATA" -path "*Release-watchsimulator*" -name "SpeedManagerModule.o" | head -1)
if [[ -n "$WATCHOS_SIM_BINARY" && -f "$WATCHOS_SIM_BINARY" ]]; then
    cp "$WATCHOS_SIM_BINARY" "$WATCHOS_SIM_DIR/SpeedManagerModule.framework/SpeedManagerModule"
    echo "  ✅ watchOS Simulator binary copied"
else
    echo "  ❌ watchOS Simulator binary not found"
    exit 1
fi

# Copy watchOS Simulator Swift modules
WATCHOS_SIM_MODULE_DIR=$(find "$DERIVED_DATA" -path "*Release-watchsimulator*" -name "SpeedManagerModule.swiftmodule" -type d | head -1)
if [[ -n "$WATCHOS_SIM_MODULE_DIR" && -d "$WATCHOS_SIM_MODULE_DIR" ]]; then
    cp -r "$WATCHOS_SIM_MODULE_DIR"/* "$WATCHOS_SIM_DIR/SpeedManagerModule.framework/Modules/SpeedManagerModule.swiftmodule/"
    echo "  ✅ watchOS Simulator Swift modules copied"
fi

# Create framework Info.plist for watchOS Device
cat > "$WATCHOS_DIR/SpeedManagerModule.framework/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
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
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>WatchOS</string>
    </array>
    <key>MinimumOSVersion</key>
    <string>8.0</string>
</dict>
</plist>
EOF

# Create framework Info.plist for watchOS Simulator
cat > "$WATCHOS_SIM_DIR/SpeedManagerModule.framework/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
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
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>WatchSimulator</string>
    </array>
    <key>MinimumOSVersion</key>
    <string>8.0</string>
</dict>
</plist>
EOF

echo "🔨 Creating new XCFramework with watchOS support..."

# Create new XCFramework with all platforms
xcodebuild -create-xcframework \
    -framework "Build/SpeedManagerModule.xcframework/ios-arm64/SpeedManagerModule.framework" \
    -framework "Build/SpeedManagerModule.xcframework/ios-arm64_x86_64-simulator/SpeedManagerModule.framework" \
    -framework "$WATCHOS_DIR/SpeedManagerModule.framework" \
    -framework "$WATCHOS_SIM_DIR/SpeedManagerModule.framework" \
    -output "Build/SpeedManagerModule_with_watchOS.xcframework"

if [[ -d "Build/SpeedManagerModule_with_watchOS.xcframework" ]]; then
    echo "✅ New XCFramework with watchOS support created!"
    
    # Replace the old XCFramework
    rm -rf "Build/SpeedManagerModule.xcframework"
    mv "Build/SpeedManagerModule_with_watchOS.xcframework" "Build/SpeedManagerModule.xcframework"
    
    # Clean up temp directories
    rm -rf "Build/Temp"
    
    echo "📊 Updated XCFramework structure:"
    find "Build/SpeedManagerModule.xcframework" -name "SpeedManagerModule" -type f -exec ls -lh {} \;
    
    echo "🔍 Platform verification:"
    find "Build/SpeedManagerModule.xcframework" -name "SpeedManagerModule" -type f -exec file {} \;
    
    # Update the ZIP
    echo "📦 Creating updated distribution ZIP..."
    cd Build
    rm -f SpeedManagerModule.xcframework.zip
    zip -r "SpeedManagerModule.xcframework.zip" "SpeedManagerModule.xcframework"
    echo "✅ Updated SpeedManagerModule.xcframework.zip"
    cd ..
    
    echo "🎉 Successfully added watchOS support to XCFramework!"
    echo "📱 Platforms: iOS (device + simulator), watchOS (device + simulator)"
    
else
    echo "❌ Failed to create XCFramework with watchOS support"
    # Restore backup
    rm -rf "Build/SpeedManagerModule.xcframework" 
    mv "Build/SpeedManagerModule.xcframework.backup" "Build/SpeedManagerModule.xcframework"
    exit 1
fi