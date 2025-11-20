#!/bin/bash

# MacWallpaper Build Script
# This script helps build the MacWallpaper application

echo "🎬 MacWallpaper Build Script"
echo "============================"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This application can only be built on macOS"
    exit 1
fi

# Check if Swift is installed
if ! command -v swift &> /dev/null; then
    echo "❌ Error: Swift is not installed"
    echo "Please install Xcode or Swift toolchain from https://swift.org/download/"
    exit 1
fi

echo "✅ Swift version:"
swift --version
echo ""

# Clean build directory
echo "🧹 Cleaning build directory..."
rm -rf .build
echo ""

# Build the project
echo "🔨 Building MacWallpaper..."
if swift build -c release; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "📦 Binary location: .build/release/MacWallpaper"
    echo ""
    echo "To run the application:"
    echo "  .build/release/MacWallpaper"
    echo ""
else
    echo ""
    echo "❌ Build failed"
    exit 1
fi
