#!/bin/bash

# Build script for creating XCFramework for SpeedManagerModule Swift Package
# This script creates a proper XCFramework for distribution

set -e

FRAMEWORK_NAME="SpeedManagerModule"
PROJECT_NAME="$FRAMEWORK_NAME"
WORKSPACE_DIR="./XCFrameworkBuild"
PROJECT_DIR="$WORKSPACE_DIR/$PROJECT_NAME"
OUTPUT_DIR="./Build"
ARCHIVE_DIR="$OUTPUT_DIR/Archives"
XCFRAMEWORK_PATH="$OUTPUT_DIR/$FRAMEWORK_NAME.xcframework"

echo "🚀 Creating XCFramework for $FRAMEWORK_NAME"
echo "================================================="

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "$OUTPUT_DIR" "$WORKSPACE_DIR"
mkdir -p "$ARCHIVE_DIR" "$PROJECT_DIR"

# Step 1: Create a temporary Xcode project that wraps our Swift package
echo "📦 Creating temporary Xcode project wrapper..."
cd "$PROJECT_DIR"

# Create an Xcode project using swift package generate-xcodeproj
echo "🔧 Generating Xcode project from Swift package..."
cd "../.." # Go back to package root
swift package generate-xcodeproj --output "$PROJECT_DIR"

# Copy the generated project to our workspace
if [ -d "$FRAMEWORK_NAME.xcodeproj" ]; then
    mv "$FRAMEWORK_NAME.xcodeproj" "$PROJECT_DIR/"
    PROJECT_PATH="$PROJECT_DIR/$FRAMEWORK_NAME.xcodeproj"
else
    echo "❌ Failed to generate Xcode project"
    exit 1
fi

echo "✅ Xcode project created at $PROJECT_PATH"

# Step 2: Build archives for each platform
echo "📱 Building archives for all platforms..."

# Function to create archive
create_archive() {
    local destination="$1"
    local archive_name="$2"
    local archive_path="$ARCHIVE_DIR/$archive_name.xcarchive"
    
    echo "🔨 Creating archive for $archive_name..."
    
    xcodebuild archive \
        -project "$PROJECT_PATH" \
        -scheme "$FRAMEWORK_NAME-Package" \
        -destination "$destination" \
        -archivePath "$archive_path" \
        -sdk $(echo "$destination" | grep -o 'platform=[^,]*' | cut -d'=' -f2 | tr '[:upper:]' '[:lower:]') \
        SKIP_INSTALL=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        ONLY_ACTIVE_ARCH=NO \
        INSTALL_PATH='@rpath'
        
    if [ ! -d "$archive_path" ]; then
        echo "❌ Failed to create archive for $archive_name"
        return 1
    fi
    
    echo "✅ Archive created: $archive_path"
}

# Create archives for all platforms
create_archive "generic/platform=iOS" "iOS"
create_archive "generic/platform=iOS Simulator" "iOS-Simulator"  
create_archive "generic/platform=watchOS" "watchOS"
create_archive "generic/platform=watchOS Simulator" "watchOS-Simulator"

# Step 3: Locate the frameworks in archives
echo "🔍 Locating frameworks in archives..."

find_framework_in_archive() {
    local archive_path="$1"
    local platform_name="$2"
    
    # Look for the framework in common locations within the archive
    local framework_path
    framework_path=$(find "$archive_path" -name "$FRAMEWORK_NAME.framework" -type d | head -1)
    
    if [ -z "$framework_path" ]; then
        echo "❌ Framework not found in archive for $platform_name"
        echo "Archive contents:"
        find "$archive_path" -type d -name "*.framework"
        return 1
    fi
    
    echo "$framework_path"
}

# Find frameworks
IOS_FRAMEWORK=$(find_framework_in_archive "$ARCHIVE_DIR/iOS.xcarchive" "iOS")
IOS_SIM_FRAMEWORK=$(find_framework_in_archive "$ARCHIVE_DIR/iOS-Simulator.xcarchive" "iOS Simulator")
WATCHOS_FRAMEWORK=$(find_framework_in_archive "$ARCHIVE_DIR/watchOS.xcarchive" "watchOS")
WATCHOS_SIM_FRAMEWORK=$(find_framework_in_archive "$ARCHIVE_DIR/watchOS-Simulator.xcarchive" "watchOS Simulator")

echo "✅ All frameworks located successfully"

# Step 4: Create XCFramework
echo "🔨 Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "$IOS_FRAMEWORK" \
    -framework "$IOS_SIM_FRAMEWORK" \
    -framework "$WATCHOS_FRAMEWORK" \
    -framework "$WATCHOS_SIM_FRAMEWORK" \
    -output "$XCFRAMEWORK_PATH"

if [ ! -d "$XCFRAMEWORK_PATH" ]; then
    echo "❌ Failed to create XCFramework"
    exit 1
fi

echo "✅ XCFramework created successfully!"

# Step 5: Create distribution package
echo "📦 Creating distribution package..."
cd "$OUTPUT_DIR"

# Compress the XCFramework
zip -r "$FRAMEWORK_NAME.xcframework.zip" "$FRAMEWORK_NAME.xcframework"

# Compute checksum
CHECKSUM=$(swift package compute-checksum "$FRAMEWORK_NAME.xcframework.zip" 2>/dev/null || shasum -a 256 "$FRAMEWORK_NAME.xcframework.zip" | cut -d' ' -f1)
echo "$CHECKSUM" > "$FRAMEWORK_NAME.xcframework.zip.checksum"

# Step 6: Create binary Package.swift template
cat > "BinaryPackage.swift" << EOF
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

# Step 7: Cleanup temporary files
echo "🧹 Cleaning up temporary files..."
rm -rf "../$WORKSPACE_DIR"

# Step 8: Display results
echo ""
echo "🎉 XCFramework build completed successfully!"
echo "================================================="
echo "📁 Build artifacts:"
echo "   📱 XCFramework: $XCFRAMEWORK_PATH"
echo "   📦 Compressed: $FRAMEWORK_NAME.xcframework.zip"
echo "   🔐 Checksum: $CHECKSUM"
echo "   📄 Binary Package Template: BinaryPackage.swift"
echo ""
echo "📋 Next steps:"
echo "1. Upload $FRAMEWORK_NAME.xcframework.zip to GitHub releases"
echo "2. Update the URL in BinaryPackage.swift with the actual release URL"
echo "3. Replace your Package.swift with the binary target configuration"
echo "4. Tag your release and publish"
echo ""
echo "💡 Tip: You can also distribute the XCFramework directly or via CocoaPods"

echo "✅ XCFramework created successfully at: $XCFRAMEWORK_PATH"

# Create checksum for the XCFramework
echo "🔐 Computing checksum..."
cd "$OUTPUT_DIR"
CHECKSUM=$(swift package compute-checksum "$FRAMEWORK_NAME.xcframework.zip" 2>/dev/null || echo "")

if [ -z "$CHECKSUM" ]; then
    # If swift package compute-checksum is not available, use shasum
    zip -r "$FRAMEWORK_NAME.xcframework.zip" "$FRAMEWORK_NAME.xcframework"
    CHECKSUM=$(shasum -a 256 "$FRAMEWORK_NAME.xcframework.zip" | cut -d' ' -f1)
    echo "Checksum: $CHECKSUM"
    echo "$CHECKSUM" > "$FRAMEWORK_NAME.xcframework.zip.checksum"
else
    zip -r "$FRAMEWORK_NAME.xcframework.zip" "$FRAMEWORK_NAME.xcframework"
    echo "Checksum: $CHECKSUM"
    echo "$CHECKSUM" > "$FRAMEWORK_NAME.xcframework.zip.checksum"
fi

echo "📁 Build artifacts:"
echo "   - XCFramework: $XCFRAMEWORK_PATH"
echo "   - Zipped: $OUTPUT_DIR/$FRAMEWORK_NAME.xcframework.zip"
echo "   - Checksum: $OUTPUT_DIR/$FRAMEWORK_NAME.xcframework.zip.checksum"

echo ""
echo "🎉 Build completed successfully!"
echo ""
echo "To distribute as a binary package, upload the .xcframework.zip to a release"
echo "and update your Package.swift with the binary target configuration."