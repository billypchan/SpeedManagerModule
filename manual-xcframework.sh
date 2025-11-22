#!/bin/bash

set -e

echo "🚀 Creating XCFramework manually..."

# Clean up and prepare
rm -rf Build
mkdir -p Build/SpeedManagerModule.xcframework

# Find the DerivedData path
DERIVED_DATA=$(find ~/Library/Developer/Xcode/DerivedData -name "SpeedManagerModule-*" -type d | head -1)
echo "📁 Using DerivedData: $DERIVED_DATA"

# Create iOS Device slice
echo "📱 Creating iOS Device slice..."
IOS_DIR="Build/SpeedManagerModule.xcframework/ios-arm64"
mkdir -p "$IOS_DIR/SpeedManagerModule.framework/Modules/SpeedManagerModule.swiftmodule"

# Copy iOS binary
IOS_BINARY=$(find "$DERIVED_DATA" -path "*Release-iphoneos*" -name "SpeedManagerModule.o" | head -1)
cp "$IOS_BINARY" "$IOS_DIR/SpeedManagerModule.framework/SpeedManagerModule"

# Copy iOS Swift modules
IOS_MODULE_DIR=$(find "$DERIVED_DATA" -path "*Release-iphoneos*" -name "SpeedManagerModule.swiftmodule" -type d | head -1)
if [[ -d "$IOS_MODULE_DIR" ]]; then
    cp -r "$IOS_MODULE_DIR"/* "$IOS_DIR/SpeedManagerModule.framework/Modules/SpeedManagerModule.swiftmodule/"
fi

# Create iOS Simulator slice
echo "🖥️ Creating iOS Simulator slice..."
SIM_DIR="Build/SpeedManagerModule.xcframework/ios-arm64_x86_64-simulator"
mkdir -p "$SIM_DIR/SpeedManagerModule.framework/Modules/SpeedManagerModule.swiftmodule"

# Copy simulator binary
SIM_BINARY=$(find "$DERIVED_DATA" -path "*Release-iphonesimulator*" -name "SpeedManagerModule.o" | head -1)
cp "$SIM_BINARY" "$SIM_DIR/SpeedManagerModule.framework/SpeedManagerModule"

# Copy simulator Swift modules
SIM_MODULE_DIR=$(find "$DERIVED_DATA" -path "*Release-iphonesimulator*" -name "SpeedManagerModule.swiftmodule" -type d | head -1)
if [[ -d "$SIM_MODULE_DIR" ]]; then
    cp -r "$SIM_MODULE_DIR"/* "$SIM_DIR/SpeedManagerModule.framework/Modules/SpeedManagerModule.swiftmodule/"
fi

# Create framework Info.plist for iOS
cat > "$IOS_DIR/SpeedManagerModule.framework/Info.plist" << EOF
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
        <string>iPhoneOS</string>
    </array>
    <key>MinimumOSVersion</key>
    <string>15.0</string>
</dict>
</plist>
EOF

# Create framework Info.plist for Simulator
cat > "$SIM_DIR/SpeedManagerModule.framework/Info.plist" << EOF
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
        <string>iPhoneSimulator</string>
    </array>
    <key>MinimumOSVersion</key>
    <string>15.0</string>
</dict>
</plist>
EOF

# Create XCFramework Info.plist
cat > "Build/SpeedManagerModule.xcframework/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>AvailableLibraries</key>
    <array>
        <dict>
            <key>LibraryIdentifier</key>
            <string>ios-arm64</string>
            <key>LibraryPath</key>
            <string>SpeedManagerModule.framework</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64</string>
            </array>
            <key>SupportedPlatform</key>
            <string>ios</string>
        </dict>
        <dict>
            <key>LibraryIdentifier</key>
            <string>ios-arm64_x86_64-simulator</string>
            <key>LibraryPath</key>
            <string>SpeedManagerModule.framework</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64</string>
                <string>x86_64</string>
            </array>
            <key>SupportedPlatform</key>
            <string>ios</string>
            <key>SupportedPlatformVariant</key>
            <string>simulator</string>
        </dict>
    </array>
    <key>CFBundlePackageType</key>
    <string>XFWK</string>
    <key>XCFrameworkFormatVersion</key>
    <string>1.0</string>
</dict>
</plist>
EOF

echo "✅ XCFramework created manually!"

# Replace the old one
if [[ -d "Build/SpeedManagerModule.xcframework" ]]; then
    # Backup the placeholder one
    if [[ -d "Build.old" ]]; then
        rm -rf "Build.old"
    fi
    if [[ -d "./Build" ]]; then
        mv "./Build" "./Build.old"
    fi
    mv "Build" "./"
    
    echo "🎉 Real XCFramework with binaries created!"
    echo "📁 Location: Build/SpeedManagerModule.xcframework"
    
    echo "📊 XCFramework structure:"
    find "Build/SpeedManagerModule.xcframework" -type f | sort
    
    echo "📦 Binary sizes:"
    find "Build/SpeedManagerModule.xcframework" -name "SpeedManagerModule" -type f -exec ls -lh {} \;
    
    # Create ZIP
    cd Build
    zip -r "SpeedManagerModule.xcframework.zip" "SpeedManagerModule.xcframework"
    echo "📦 Created SpeedManagerModule.xcframework.zip"
    cd ..
    
else
    echo "❌ XCFramework creation failed!"
    exit 1
fi