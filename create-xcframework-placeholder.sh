#!/bin/bash

set -e

echo "🚀 Creating XCFramework for SpeedManagerModule v0.1.1"
echo "====================================================="

# Clean previous builds
rm -rf Build/SpeedManagerModule.xcframework
rm -rf Build/SpeedManagerModule.xcframework.zip

echo "📦 Note: For Swift Package Manager binary distribution,"
echo "   we'll use source distribution as the most reliable method."
echo ""
echo "💡 Alternative approaches:"
echo "   1. Use source Package.swift (recommended for SPM)"
echo "   2. Create manual XCFramework for CocoaPods/manual integration"
echo "   3. Use GitHub releases with pre-built archives"
echo ""

# Create a symbolic XCFramework structure for demonstration
mkdir -p Build/SpeedManagerModule.xcframework

cat > Build/SpeedManagerModule.xcframework/Info.plist << EOF
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
        <dict>
            <key>LibraryIdentifier</key>
            <string>macos-arm64_x86_64</string>
            <key>LibraryPath</key>
            <string>SpeedManagerModule.framework</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64</string>
                <string>x86_64</string>
            </array>
            <key>SupportedPlatform</key>
            <string>macos</string>
        </dict>
        <dict>
            <key>LibraryIdentifier</key>
            <string>watchos-arm64_32_armv7k</string>
            <key>LibraryPath</key>
            <string>SpeedManagerModule.framework</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64_32</string>
                <string>armv7k</string>
            </array>
            <key>SupportedPlatform</key>
            <string>watchos</string>
        </dict>
        <dict>
            <key>LibraryIdentifier</key>
            <string>watchos-arm64_x86_64-simulator</string>
            <key>LibraryPath</key>
            <string>SpeedManagerModule.framework</string>
            <key>SupportedArchitectures</key>
            <array>
                <string>arm64</string>
                <string>x86_64</string>
            </array>
            <key>SupportedPlatform</key>
            <string>watchos</string>
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

echo "📋 Created XCFramework Info.plist"
echo "⚠️  Note: This is a placeholder structure."
echo "   For production use, recommend using source distribution via Package.swift"

# Create a zip for potential release use
cd Build
zip -r SpeedManagerModule.xcframework.zip SpeedManagerModule.xcframework/
cd ..

echo ""
echo "✅ XCFramework structure created!"
echo "📁 Location: Build/SpeedManagerModule.xcframework"
echo "📦 Archive: Build/SpeedManagerModule.xcframework.zip"
echo ""
echo "🔧 Next steps:"
echo "   • For SPM: Use source Package.swift (most reliable)"
echo "   • For releases: Upload zip to GitHub releases"
echo "   • For local dev: Package-Binary.swift now points to local path"