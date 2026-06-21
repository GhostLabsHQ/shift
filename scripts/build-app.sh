#!/bin/bash
# Build a distributable Shift.app and zip it. No Apple Developer account needed.
#
# Usage:
#   ./scripts/build-app.sh                          # native arch (Command Line Tools OK)
#   ARCHS="arm64 x86_64" ./scripts/build-app.sh     # universal (needs full Xcode)
#
# Output: dist/Shift.app and dist/Shift.zip
#
# The app is ad-hoc signed. On the target Mac, if Gatekeeper blocks it, run once:
#   xattr -dr com.apple.quarantine /Applications/Shift.app

set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Shift"
BUNDLE_ID="app.shift.Shift"
VERSION="0.1.0"
BUILD_NUM="1"
ARCHS="${ARCHS:-}"                     # empty = native arch

DIST="dist"
APP="$DIST/$APP_NAME.app"
MACOS_DIR="$APP/Contents/MacOS"
RES_DIR="$APP/Contents/Resources"

ARCH_FLAGS=""
for a in $ARCHS; do ARCH_FLAGS="$ARCH_FLAGS --arch $a"; done

echo "==> Building release (${ARCHS:-native})..."
# Build only the Shift product (the ShiftTests target uses @testable, which isn't
# available in release config).
swift build -c release $ARCH_FLAGS --product "$APP_NAME"
BIN_DIR="$(swift build -c release $ARCH_FLAGS --product "$APP_NAME" --show-bin-path)"

echo "==> Assembling $APP ..."
rm -rf "$APP"
mkdir -p "$MACOS_DIR" "$RES_DIR"
cp "$BIN_DIR/$APP_NAME" "$MACOS_DIR/$APP_NAME"
printf 'APPL????' > "$APP/Contents/PkgInfo"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>$APP_NAME</string>
  <key>CFBundleDisplayName</key><string>$APP_NAME</string>
  <key>CFBundleExecutable</key><string>$APP_NAME</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$VERSION</string>
  <key>CFBundleVersion</key><string>$BUILD_NUM</string>
  <key>LSMinimumSystemVersion</key><string>11.0</string>
  <key>LSUIElement</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSAccessibilityUsageDescription</key><string>Shift needs accessibility access to move and resize windows.</string>
</dict>
</plist>
PLIST

# Optional icon: place assets/AppIcon.icns to bundle an app icon.
if [ -f assets/AppIcon.icns ]; then
  cp assets/AppIcon.icns "$RES_DIR/AppIcon.icns"
  /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "$APP/Contents/Info.plist" >/dev/null 2>&1 || true
fi

echo "==> Ad-hoc signing..."
codesign --force --sign - "$MACOS_DIR/$APP_NAME"
codesign --force --sign - "$APP"
codesign --verify --strict "$APP"

echo "==> Zipping..."
( cd "$DIST" && ditto -c -k --keepParent "$APP_NAME.app" "$APP_NAME.zip" )

echo ""
echo "Built: $APP"
echo "Zip:   $DIST/$APP_NAME.zip   ($(du -h "$DIST/$APP_NAME.zip" | cut -f1))"
echo "On the target Mac, if it won't open:  xattr -dr com.apple.quarantine /Applications/Shift.app"
