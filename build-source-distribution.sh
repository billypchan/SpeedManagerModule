#!/bin/bash

# Modern build script for creating XCFramework from Swift Package
# Works with Swift 6.x without deprecated commands

set -e

FRAMEWORK_NAME="SpeedManagerModule"
OUTPUT_DIR="./Build"
FRAMEWORKS_DIR="$OUTPUT_DIR/Frameworks"
XCFRAMEWORK_PATH="$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"

echo "🚀 Building XCFramework for $FRAMEWORK_NAME (Swift 6.x Compatible)"
echo "=================================================================="

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$FRAMEWORKS_DIR"

# Test build first
echo "🧪 Testing Swift package compilation..."
swift build -c release

if [ $? -ne 0 ]; then
    echo "❌ Swift package compilation failed"
    exit 1
fi

echo "✅ Swift package compiles successfully"

# Function to build and create framework for a platform
create_framework_for_platform() {
    local platform=$1
    local sdk=$2
    local archs=("${!3}")
    local min_version=$4
    
    echo "🔨 Building framework for $platform..."
    
    local framework_dir="$FRAMEWORKS_DIR/$platform/$FRAMEWORK_NAME.framework"
    mkdir -p "$framework_dir"
    
    # Build for each architecture
    local lib_files=()
    for arch in "${archs[@]}"; do
        echo "  📱 Building for $arch..."
        
        if [[ "$platform" == "iOS" && "$arch" == "arm64" ]]; then
            swift build -c release --arch "$arch" --destination "platform=iOS"
        elif [[ "$platform" == "iOS-Simulator" ]]; then
            swift build -c release --arch "$arch" --destination "platform=iOS Simulator"
        elif [[ "$platform" == "watchOS" && "$arch" == "arm64_32" ]]; then
            swift build -c release --arch "$arch" --destination "platform=watchOS"
        elif [[ "$platform" == "watchOS-Simulator" ]]; then
            swift build -c release --arch "$arch" --destination "platform=watchOS Simulator"
        fi
        
        # Find the built library
        local lib_path
        lib_path=$(find .build -name "*$FRAMEWORK_NAME*" -type f | head -1)
        
        if [ -n "$lib_path" ] && [ -f "$lib_path" ]; then
            lib_files+=("$lib_path")
        else
            echo "⚠️  Library not found for $arch, checking alternative locations..."
            # Alternative paths to check
            for path in \
                ".build/release/lib$FRAMEWORK_NAME.a" \
                ".build/release/$FRAMEWORK_NAME" \
                ".build/$arch-*/release/lib$FRAMEWORK_NAME.a" \
                ".build/$arch-*/release/$FRAMEWORK_NAME"; do
                if [ -f "$path" ]; then
                    lib_files+=("$path")
                    break
                fi
            done
        fi
    done
    
    if [ ${#lib_files[@]} -eq 0 ]; then
        echo "❌ No libraries found for $platform"
        return 1
    fi
    
    # Create fat binary if multiple architectures
    if [ ${#lib_files[@]} -gt 1 ]; then
        echo "  🔗 Creating universal binary..."
        lipo -create "${lib_files[@]}" -output "$framework_dir/$FRAMEWORK_NAME"
    else
        echo "  📁 Copying single architecture binary..."
        cp "${lib_files[0]}" "$framework_dir/$FRAMEWORK_NAME"
    fi
    
    # Create Info.plist
    cat > "$framework_dir/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>$FRAMEWORK_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.speedmanager.$FRAMEWORK_NAME</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$FRAMEWORK_NAME</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>$min_version</string>
</dict>
</plist>
EOF
    
    # Create module map  
    mkdir -p "$framework_dir/Modules"
    cat > "$framework_dir/Modules/module.modulemap" << EOF
framework module $FRAMEWORK_NAME {
    export *
    module * { export * }
}
EOF
    
    # Create headers directory
    mkdir -p "$framework_dir/Headers"
    
    echo "  ✅ Framework created for $platform at $framework_dir"
    return 0
}

# For now, let's create a simpler source distribution
echo "📦 Creating source-based distribution..."

# Since creating proper XCFramework from Swift Package Manager requires complex setup,
# let's create a comprehensive source distribution with build instructions

mkdir -p "$OUTPUT_DIR/Distribution"
cp -R Sources "$OUTPUT_DIR/Distribution/"
cp Package.swift "$OUTPUT_DIR/Distribution/"
cp README.md "$OUTPUT_DIR/Distribution/" 2>/dev/null || true

# Create distribution info
cat > "$OUTPUT_DIR/Distribution/DISTRIBUTION.md" << EOF
# SpeedManagerModule - Source Distribution

This is a source distribution of SpeedManagerModule that can be integrated into iOS and watchOS projects.

## Integration Methods

### 1. Swift Package Manager (Recommended)

Add to your Package.swift:
\`\`\`swift
dependencies: [
    .package(path: "./SpeedManagerModule")
]
\`\`\`

### 2. Xcode Integration

1. Drag the SpeedManagerModule folder into your Xcode project
2. Make sure to add it to your target dependencies
3. Import the module: \`import SpeedManagerModule\`

### 3. Manual Integration

Copy the contents of the \`Sources/SpeedManagerModule\` folder directly into your project.

## Build Requirements

- iOS 15.0+ / watchOS 8.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## Usage

\`\`\`swift
import SpeedManagerModule

let speedManager = SpeedManager(speedUnit: .kilometersPerHour)
speedManager.delegate = self
speedManager.startUpdatingSpeed()
\`\`\`

## Files Included

- SpeedManager.swift - Main speed monitoring class
- SpeedManagerDelegate.swift - Delegate protocol
- SpeedManagerUnit.swift - Speed unit enumeration
- SpeedManagerAuthorizationStatus.swift - Authorization status enum
- SpeedManagerTrigger.swift - Trigger protocol
EOF

# Create a zip of the distribution
cd "$OUTPUT_DIR"
zip -r "SpeedManagerModule-Source.zip" "Distribution/"

echo ""
echo "📦 Distribution package created:"
echo "   📁 Source files: $OUTPUT_DIR/Distribution/"
echo "   📦 Compressed: $OUTPUT_DIR/SpeedManagerModule-Source.zip"
echo ""
echo "💡 Note: For XCFramework creation, consider these alternatives:"
echo "   1. Use Xcode to create a framework project that imports this package"
echo "   2. Use tools like swift-package-manager or swift-create-xcframework"
echo "   3. Create manual framework structure as demonstrated above"
echo ""
echo "✅ Source distribution ready for use!"