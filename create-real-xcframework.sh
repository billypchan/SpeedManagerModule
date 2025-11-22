#!/bin/bash

set -e

echo "🚀 Creating XCFramework from built components..."

# Clean up and prepare
rm -rf Build
mkdir -p Build/Frameworks

# Find the DerivedData path
DERIVED_DATA=$(find ~/Library/Developer/Xcode/DerivedData -name "SpeedManagerModule-*" -type d | head -1)
if [[ -z "$DERIVED_DATA" ]]; then
    echo "❌ Could not find DerivedData folder"
    exit 1
fi

echo "📁 Using DerivedData: $DERIVED_DATA"

# iOS Device Framework
echo "📱 Creating iOS Device framework..."
IOS_FRAMEWORK="Build/Frameworks/SpeedManagerModule-iOS.framework"
mkdir -p "$IOS_FRAMEWORK/Modules/SpeedManagerModule.swiftmodule"

# Find iOS device binary
IOS_BINARY=$(find "$DERIVED_DATA" -path "*Release-iphoneos*" -name "SpeedManagerModule.o" | head -1)
if [[ -n "$IOS_BINARY" && -f "$IOS_BINARY" ]]; then
    cp "$IOS_BINARY" "$IOS_FRAMEWORK/SpeedManagerModule"
    echo "  ✅ iOS binary copied"
else
    echo "  ❌ iOS binary not found"
fi

# Find and copy iOS Swift modules
IOS_MODULE_DIR=$(find "$DERIVED_DATA" -path "*Release-iphoneos*" -name "SpeedManagerModule.swiftmodule" -type d | head -1)
if [[ -n "$IOS_MODULE_DIR" && -d "$IOS_MODULE_DIR" ]]; then
    cp -r "$IOS_MODULE_DIR"/* "$IOS_FRAMEWORK/Modules/SpeedManagerModule.swiftmodule/"
    echo "  ✅ iOS Swift modules copied"
fi

# iOS Simulator Framework  
echo "🖥️ Creating iOS Simulator framework..."
SIM_FRAMEWORK="Build/Frameworks/SpeedManagerModule-simulator.framework"
mkdir -p "$SIM_FRAMEWORK/Modules/SpeedManagerModule.swiftmodule"

# Find simulator binary
SIM_BINARY=$(find "$DERIVED_DATA" -path "*Release-iphonesimulator*" -name "SpeedManagerModule.o" | head -1)
if [[ -n "$SIM_BINARY" && -f "$SIM_BINARY" ]]; then
    cp "$SIM_BINARY" "$SIM_FRAMEWORK/SpeedManagerModule"
    echo "  ✅ Simulator binary copied"
else
    echo "  ❌ Simulator binary not found"
fi

# Find and copy simulator Swift modules
SIM_MODULE_DIR=$(find "$DERIVED_DATA" -path "*Release-iphonesimulator*" -name "SpeedManagerModule.swiftmodule" -type d | head -1)
if [[ -n "$SIM_MODULE_DIR" && -d "$SIM_MODULE_DIR" ]]; then
    cp -r "$SIM_MODULE_DIR"/* "$SIM_FRAMEWORK/Modules/SpeedManagerModule.swiftmodule/"
    echo "  ✅ Simulator Swift modules copied"
fi

# Create Info.plist for each framework
for framework in "$IOS_FRAMEWORK" "$SIM_FRAMEWORK"; do
    cat > "$framework/Info.plist" << EOF
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
</dict>
</plist>
EOF
done

echo "🔨 Creating XCFramework..."

# Create XCFramework
xcodebuild -create-xcframework \
    -framework "$IOS_FRAMEWORK" \
    -framework "$SIM_FRAMEWORK" \
    -output "Build/SpeedManagerModule.xcframework"

echo "🔍 Verifying XCFramework..."
if [[ -d "Build/SpeedManagerModule.xcframework" ]]; then
    echo "✅ XCFramework created successfully!"
    
    echo "📊 XCFramework structure:"
    find "Build/SpeedManagerModule.xcframework" -type f | head -20
    
    echo "📦 Binary sizes:"
    find "Build/SpeedManagerModule.xcframework" -name "SpeedManagerModule" -type f -exec ls -lh {} \;
    
    # Replace the old placeholder XCFramework
    rm -rf "Build.old"
    if [[ -d "Build/SpeedManagerModule.xcframework" ]]; then
        mv "Build" "Build.old"
    fi
    mv "Build" "./"
    
    echo "🎉 Real XCFramework with binaries created!"
    echo "📁 Location: Build/SpeedManagerModule.xcframework"
    
else
    echo "❌ XCFramework creation failed!"
    exit 1
fi