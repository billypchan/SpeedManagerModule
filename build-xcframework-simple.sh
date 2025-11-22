#!/bin/bash

# Alternative build script using swift-create-xcframework
# This script uses modern Swift tools to create XCFramework directly from Swift Package

set -e

FRAMEWORK_NAME="SpeedManagerModule"
OUTPUT_DIR="./Build"
XCFRAMEWORK_PATH="$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"

echo "🚀 Creating XCFramework for $FRAMEWORK_NAME using swift-create-xcframework"
echo "=============================================================================="

# Check if swift-create-xcframework is available
if ! command -v swift-create-xcframework &> /dev/null; then
    echo "❌ swift-create-xcframework is not installed."
    echo "📥 Installing swift-create-xcframework..."
    
    # Try to install using Homebrew
    if command -v brew &> /dev/null; then
        brew install swift-create-xcframework
    else
        echo "❌ Homebrew not found. Please install swift-create-xcframework manually:"
        echo "   git clone https://github.com/unsignedapps/swift-create-xcframework"
        echo "   cd swift-create-xcframework"
        echo "   make install"
        exit 1
    fi
fi

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "📦 Building XCFramework for iOS and watchOS..."

# Create XCFramework using swift-create-xcframework
swift-create-xcframework \
    --platform iOS \
    --platform watchOS \
    --output "$XCFRAMEWORK_PATH"

if [ ! -d "$XCFRAMEWORK_PATH" ]; then
    echo "❌ Failed to create XCFramework using swift-create-xcframework"
    echo "💡 Falling back to manual approach..."
    
    # Manual approach using swift build
    echo "🔨 Building manually for each platform..."
    
    # Build for iOS
    echo "📱 Building for iOS..."
    swift build -c release --arch arm64 --destination "platform=iOS"
    
    # Build for iOS Simulator  
    echo "📱 Building for iOS Simulator..."
    swift build -c release --arch arm64 --destination "platform=iOS Simulator"
    swift build -c release --arch x86_64 --destination "platform=iOS Simulator"
    
    # Build for watchOS
    echo "⌚ Building for watchOS..."
    swift build -c release --arch arm64_32 --destination "platform=watchOS"
    
    # Build for watchOS Simulator
    echo "⌚ Building for watchOS Simulator..." 
    swift build -c release --arch arm64 --destination "platform=watchOS Simulator"
    swift build -c release --arch x86_64 --destination "platform=watchOS Simulator"
    
    echo "❌ Manual build approach needs additional framework creation steps."
    echo "💡 Please use the main build-xcframework.sh script instead."
    exit 1
fi

# Create distribution package
echo "📦 Creating distribution package..."
cd "$OUTPUT_DIR"

# Compress the XCFramework
zip -r "$FRAMEWORK_NAME.xcframework.zip" "$FRAMEWORK_NAME.xcframework"

# Compute checksum
CHECKSUM=$(swift package compute-checksum "$FRAMEWORK_NAME.xcframework.zip" 2>/dev/null || shasum -a 256 "$FRAMEWORK_NAME.xcframework.zip" | cut -d' ' -f1)
echo "$CHECKSUM" > "$FRAMEWORK_NAME.xcframework.zip.checksum"

# Create binary Package.swift
cat > "Package-Binary.swift" << EOF
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "$FRAMEWORK_NAME",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "$FRAMEWORK_NAME",
            targets: ["$FRAMEWORK_NAME"]),
    ],
    targets: [
        .binaryTarget(
            name: "$FRAMEWORK_NAME",
            url: "https://github.com/your-username/your-repo/releases/download/1.0.0/$FRAMEWORK_NAME.xcframework.zip",
            checksum: "$CHECKSUM"
        ),
    ]
)
EOF

echo ""
echo "✅ XCFramework created successfully using swift-create-xcframework!"
echo "📦 Files created:"
echo "   - $FRAMEWORK_NAME.xcframework"
echo "   - $FRAMEWORK_NAME.xcframework.zip"  
echo "   - Package-Binary.swift (binary distribution template)"
echo "   - Checksum: $CHECKSUM"
echo ""
echo "🚀 Ready for distribution!"