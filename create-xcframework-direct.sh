#!/bin/bash

set -e

echo "🚀 Creating XCFramework for SpeedManagerModule"
echo "=============================================="

# Clean any existing XCFramework
rm -rf Build/SpeedManagerModule.xcframework

# Create framework-style directories for each platform
echo "📦 Building iOS Device framework..."
mkdir -p Build/Frameworks/iOS/SpeedManagerModule.framework
cp Build/iOS.xcarchive/Products/Users/bill/Objects/SpeedManagerModule.o Build/Frameworks/iOS/SpeedManagerModule.framework/SpeedManagerModule

# Copy Swift modules if they exist
if [ -d "Build/iOS.xcarchive/dSYMs/SpeedManagerModule.framework.dSYM/Contents/Resources/DWARF" ]; then
    mkdir -p Build/Frameworks/iOS/SpeedManagerModule.framework/Modules
    cp -r Build/iOS.xcarchive/dSYMs/SpeedManagerModule.framework.dSYM/Contents/Resources/DWARF Build/Frameworks/iOS/SpeedManagerModule.framework/
fi

echo "📱 Building iOS Simulator framework..."
mkdir -p Build/Frameworks/iOS-Simulator/SpeedManagerModule.framework
cp Build/iOS-Simulator.xcarchive/Products/Users/bill/Objects/SpeedManagerModule.o Build/Frameworks/iOS-Simulator/SpeedManagerModule.framework/SpeedManagerModule

echo "⌚ Building watchOS Device framework..."
mkdir -p Build/Frameworks/watchOS/SpeedManagerModule.framework
cp Build/watchOS.xcarchive/Products/Users/bill/Objects/SpeedManagerModule.o Build/Frameworks/watchOS/SpeedManagerModule.framework/SpeedManagerModule

echo "⌚ Building watchOS Simulator framework..."
mkdir -p Build/Frameworks/watchOS-Simulator/SpeedManagerModule.framework
cp Build/watchOS-Simulator.xcarchive/Products/Users/bill/Objects/SpeedManagerModule.o Build/Frameworks/watchOS-Simulator/SpeedManagerModule.framework/SpeedManagerModule

echo "🖥️  Building macOS framework..."
mkdir -p Build/Frameworks/macOS/SpeedManagerModule.framework
cp Build/macOS.xcarchive/Products/Users/bill/Objects/SpeedManagerModule.o Build/Frameworks/macOS/SpeedManagerModule.framework/SpeedManagerModule

echo "🏗️  Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework Build/Frameworks/iOS/SpeedManagerModule.framework \
    -framework Build/Frameworks/iOS-Simulator/SpeedManagerModule.framework \
    -framework Build/Frameworks/watchOS/SpeedManagerModule.framework \
    -framework Build/Frameworks/watchOS-Simulator/SpeedManagerModule.framework \
    -framework Build/Frameworks/macOS/SpeedManagerModule.framework \
    -output Build/SpeedManagerModule.xcframework

echo "📦 Creating distribution zip..."
cd Build
zip -r SpeedManagerModule.xcframework.zip SpeedManagerModule.xcframework/
cd ..

echo "✅ XCFramework created successfully!"
echo "📁 Location: Build/SpeedManagerModule.xcframework"
echo "📦 Distribution: Build/SpeedManagerModule.xcframework.zip"

# Calculate checksum for Package.swift
echo "🔐 Calculating checksum..."
CHECKSUM=$(swift package compute-checksum Build/SpeedManagerModule.xcframework.zip)
echo "📋 Checksum: $CHECKSUM"
echo "   Use this checksum in your Package.swift binary target"