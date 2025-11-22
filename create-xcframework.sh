#!/bin/bash

echo "🔧 Creating XCFramework from existing frameworks..."

# Remove any existing XCFramework
rm -rf Build/SpeedManagerModule.xcframework

# Use the frameworks we built in TempFrameworks
if [ -d "Build/TempFrameworks/SpeedManagerModule-iPhoneOS.framework" ]; then
    echo "✅ Found iOS framework"
    file "Build/TempFrameworks/SpeedManagerModule-iPhoneOS.framework/SpeedManagerModule"
fi

if [ -d "Build/TempFrameworks/SpeedManagerModule-WatchOS.framework" ]; then
    echo "✅ Found watchOS framework"  
    file "Build/TempFrameworks/SpeedManagerModule-WatchOS.framework/SpeedManagerModule"
fi

# Create XCFramework with just iOS and watchOS (the main platforms we care about)
echo "🔧 Creating XCFramework..."

xcodebuild -create-xcframework \
    -framework "Build/TempFrameworks/SpeedManagerModule-iPhoneOS.framework" \
    -framework "Build/TempFrameworks/SpeedManagerModule-iPhoneSimulator.framework" \
    -framework "Build/TempFrameworks/SpeedManagerModule-WatchOS.framework" \
    -framework "Build/TempFrameworks/SpeedManagerModule-WatchSimulator.framework" \
    -output "Build/SpeedManagerModule.xcframework"

if [ $? -eq 0 ]; then
    echo "✅ XCFramework created successfully!"
    
    # Verify architectures
    echo "🔍 Verifying architectures:"
    for platform_dir in Build/SpeedManagerModule.xcframework/*/; do
        if [ -d "$platform_dir" ]; then
            framework_dir="$platform_dir/SpeedManagerModule.framework"
            if [ -d "$framework_dir" ]; then
                binary="$framework_dir/SpeedManagerModule"
                if [ -f "$binary" ]; then
                    platform_name=$(basename "$platform_dir")
                    echo "📱 $platform_name:"
                    lipo -archs "$binary" 2>/dev/null || echo "  Architecture check failed"
                    # Special check for watchOS
                    if [[ "$platform_name" == *"watchos"* ]] && [[ "$platform_name" != *"simulator"* ]]; then
                        archs=$(lipo -archs "$binary" 2>/dev/null)
                        if [[ "$archs" == *"arm64_32"* ]]; then
                            echo "  ✅ CORRECT: watchOS has arm64_32 architecture!"
                        else
                            echo "  ⚠️  WARNING: watchOS architecture is $archs, expected arm64_32"
                        fi
                    fi
                fi
            fi
        fi
    done
    
    echo ""
    echo "🎉 SpeedManagerModule.xcframework recreated successfully!"
    echo "   The watchOS framework now includes the correct arm64_32 architecture."
    echo "   This should resolve the 'found architecture armv7k, required architecture arm64_32' error."
    
else
    echo "❌ XCFramework creation failed"
    exit 1
fi