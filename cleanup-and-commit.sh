#!/bin/bash

# Clean up and commit the recreated XCFramework

echo "🧹 Cleaning up build artifacts..."

# Remove temporary build files we don't need to commit
rm -rf Build/DerivedData
rm -rf Build/Archives  
rm -rf Build/Frameworks

# Keep the important files:
# - Build/SpeedManagerModule.xcframework/ (the main deliverable)
# - Build/TempFrameworks/ (for reference)

echo "📋 Checking git status..."
git status

echo "📦 Adding files to git..."
git add Package.swift
git add Build/SpeedManagerModule.xcframework/
git add Build/TempFrameworks/
git add XCFRAMEWORK-STATUS.md
git add build-frameworks.sh
git add create-xcframework.sh

echo "💾 Committing changes..."
git commit -m "feat: Recreate SpeedManagerModule.xcframework with correct watchOS arm64_32 architecture

- Built new frameworks with proper architectures for all platforms
- watchOS framework now uses arm64_32 instead of problematic armv7k  
- This resolves 'found architecture armv7k, required architecture arm64_32' error
- Package.swift configured for binary distribution (useBinaryTarget = true)
- XCFramework ready for watchOS 9+ device builds

Architectures:
- iOS Device: arm64
- iOS Simulator: arm64 + x86_64  
- watchOS Device: arm64_32 (FIXED)
- watchOS Simulator: arm64 + x86_64"

echo "✅ Cleanup and commit complete!"
echo "🎉 SpeedManagerModule.xcframework is ready with correct watchOS architecture!"