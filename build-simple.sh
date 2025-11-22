#!/bin/bash

# Simple XCFramework creation using swift build
set -e

echo "🚀 Creating XCFramework for SpeedManagerModule..."

# Clean previous builds  
echo "🧹 Cleaning previous builds..."
rm -rf Build/SpeedManagerModule.xcframework
rm -rf .build

echo "📱 Building for iOS..."
swift build -c release --arch arm64 --sdk $(xcrun --sdk iphoneos --show-sdk-path)

echo "🖥️ Building for iOS Simulator..."  
swift build -c release --arch arm64 --arch x86_64 --sdk $(xcrun --sdk iphonesimulator --show-sdk-path)

echo "⌚ Building for watchOS..."
swift build -c release --arch arm64_32 --sdk $(xcrun --sdk watchos --show-sdk-path)

echo "⌚🖥️ Building for watchOS Simulator..."
swift build -c release --arch arm64 --arch x86_64 --sdk $(xcrun --sdk watchsimulator --show-sdk-path)

echo "💻 Building for macOS..."
swift build -c release --arch arm64 --arch x86_64

echo "✅ All builds completed!"
echo "📁 Build artifacts:"
find .build -name "libSpeedManagerModule*" -type f | head -10