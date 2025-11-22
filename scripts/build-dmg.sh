#!/usr/bin/env bash
set -euo pipefail

# Build and package MacWallpaper into a .app bundle and DMG

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

APP_NAME="MacWallpaper"
BUNDLE_ID="com.horldsence.MacWallpaper"
VERSION="${1:-1.0}"

# Choose build directory compatible with CI layout
ARCH="$(uname -m)" # arm64 or x86_64
BUILD_DIR=".build/macos-${ARCH}"

echo "==> Building $APP_NAME (Release)"
swift build -c release --build-path "$BUILD_DIR"

BIN_PATH="$BUILD_DIR/release/$APP_NAME"
if [[ ! -f "$BIN_PATH" ]]; then
  echo "Error: built binary not found at $BIN_PATH"
  exit 1
fi

DIST_DIR="dist"
APP_DIR="$DIST_DIR/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RES_DIR="$CONTENTS_DIR/Resources"

echo "==> Creating app bundle at $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RES_DIR"

echo "==> Copying executable"
cp "$BIN_PATH" "$MACOS_DIR/$APP_NAME"
chmod +x "$MACOS_DIR/$APP_NAME"

echo "==> Preparing Info.plist"
# Use the project Info.plist as template
PLIST_SRC="Resources/Info.plist"
PLIST_DST="$CONTENTS_DIR/Info.plist"
cp "$PLIST_SRC" "$PLIST_DST"

# Ensure required fields are correct
/usr/libexec/PlistBuddy -c "Set :CFBundleExecutable $APP_NAME" "$PLIST_DST" || true
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" "$PLIST_DST" || true
/usr/libexec/PlistBuddy -c "Set :CFBundleName $APP_NAME" "$PLIST_DST" || true
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PLIST_DST" || true
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion 1" "$PLIST_DST" || true
/usr/libexec/PlistBuddy -c "Set :CFBundlePackageType APPL" "$PLIST_DST" || true
/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "$PLIST_DST" || true

echo "==> Copying app icon"
cp "Resources/AppIcon.icns" "$RES_DIR/AppIcon.icns"

echo "==> Creating DMG"
mkdir -p "$DIST_DIR"
DMG_PATH="$DIST_DIR/$APP_NAME.dmg"
rm -f "$DMG_PATH"
hdiutil create -volname "$APP_NAME" -srcfolder "$APP_DIR" -ov -format UDZO "$DMG_PATH"

echo "==> Done"
echo "App bundle: $APP_DIR"
echo "DMG: $DMG_PATH"