#!/bin/bash

# SpeedManagerModule Distribution Helper
# Shows available distribution options and builds them

set -e

echo "🚀 SpeedManagerModule Distribution Helper"
echo "========================================"
echo ""

# Check available scripts
echo "📋 Available Build Scripts:"
echo ""

if [ -x "./build-source-distribution.sh" ]; then
    echo "✅ Source Distribution (Recommended)"
    echo "   Script: ./build-source-distribution.sh"
    echo "   Status: Ready to use"
    echo ""
fi

if [ -x "./build-xcframework.sh" ]; then
    echo "⚠️  XCFramework (Full Build)"
    echo "   Script: ./build-xcframework.sh"
    echo "   Status: Requires Xcode project wrapper"
    echo ""
fi

if [ -x "./build-xcframework-modern.sh" ]; then
    echo "⚠️  XCFramework (Modern)"
    echo "   Script: ./build-xcframework-modern.sh"
    echo "   Status: Experimental - Limited SPM support"
    echo ""
fi

if [ -x "./build-xcframework-simple.sh" ]; then
    echo "⚠️  XCFramework (Simple)"
    echo "   Script: ./build-xcframework-simple.sh"
    echo "   Status: Requires swift-create-xcframework tool"
    echo ""
fi

echo "📖 Documentation:"
echo "   📄 BINARY-PACKAGE-GUIDE.md - Complete guide"
echo "   📄 README-Complete.md - Usage examples"
echo "   📄 README-Binary.md - Binary distribution info"
echo ""

# Interactive menu
echo "🎯 What would you like to do?"
echo ""
echo "1) Build source distribution (Recommended)"
echo "2) Try XCFramework build (Experimental)"  
echo "3) Show package info"
echo "4) Open documentation"
echo "5) Exit"
echo ""

read -p "Choose an option (1-5): " choice

case $choice in
    1)
        echo ""
        echo "🔨 Building source distribution..."
        ./build-source-distribution.sh
        ;;
    2)
        echo ""
        echo "🧪 Attempting XCFramework build..."
        echo "⚠️  Note: This may fail due to Swift Package Manager limitations"
        echo ""
        if [ -x "./build-xcframework-modern.sh" ]; then
            ./build-xcframework-modern.sh
        else
            echo "❌ Modern XCFramework script not found"
        fi
        ;;
    3)
        echo ""
        echo "📦 SpeedManagerModule Package Information"
        echo "========================================"
        echo ""
        if [ -f "Package.swift" ]; then
            echo "📄 Package.swift found:"
            echo ""
            grep -A 10 "let package = Package" Package.swift || cat Package.swift
            echo ""
        fi
        
        if [ -d "Sources" ]; then
            echo "📁 Source files:"
            find Sources -name "*.swift" -exec echo "   {}" \;
            echo ""
        fi
        
        echo "🎯 Supported Platforms:"
        echo "   📱 iOS 15.0+"
        echo "   ⌚ watchOS 8.0+"
        echo "   💻 macOS 12.0+"
        echo ""
        ;;
    4)
        echo ""
        echo "📚 Opening documentation..."
        if command -v open &> /dev/null; then
            open README-Complete.md 2>/dev/null || echo "Please open README-Complete.md manually"
        else
            echo "Please open README-Complete.md in your preferred editor"
        fi
        ;;
    5)
        echo ""
        echo "👋 Goodbye!"
        exit 0
        ;;
    *)
        echo ""
        echo "❌ Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo ""
echo "✅ Operation completed!"
echo ""
echo "📋 Quick Integration:"
echo "Add to your Package.swift dependencies:"
echo ""
echo '.package(url: "https://github.com/billypchan/SpeedManagerModule.git", from: "1.0.0")'
echo ""
echo "📖 For detailed usage examples, see README-Complete.md"