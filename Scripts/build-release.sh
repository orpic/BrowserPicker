#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
SCHEME="BrowserPicker"
APP_NAME="BrowserPicker"

VERSION="${1:-1.0.0}"

echo "=== Building $APP_NAME v$VERSION ==="

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "--- xcodebuild archive ---"
xcodebuild archive \
    -project "$PROJECT_DIR/$APP_NAME.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$BUILD_DIR/$APP_NAME.xcarchive" \
    -quiet \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_ALLOWED=NO

APP_PATH="$BUILD_DIR/$APP_NAME.xcarchive/Products/Applications/$APP_NAME.app"

if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: $APP_PATH not found"
    exit 1
fi

echo "--- Creating DMG ---"
if ! command -v create-dmg &> /dev/null; then
    echo "ERROR: create-dmg not found. Install with: brew install create-dmg"
    exit 1
fi

DMG_NAME="$APP_NAME-$VERSION.dmg"

create-dmg \
    --volname "$APP_NAME" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 175 190 \
    --hide-extension "$APP_NAME.app" \
    --app-drop-link 425 190 \
    "$BUILD_DIR/$DMG_NAME" \
    "$APP_PATH" \
    || true

if [ -f "$BUILD_DIR/$DMG_NAME" ]; then
    echo "=== Done: $BUILD_DIR/$DMG_NAME ==="
else
    echo "ERROR: DMG creation failed"
    exit 1
fi
