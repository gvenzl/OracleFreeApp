#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="OracleFreeApp"
APP_DISPLAY_NAME="Oracle Free App"
APP_VERSION="1.0.0"
BUNDLE_ID="com.oraclefreeapp.OracleFreeApp"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_DISPLAY_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
APP_ICON_SOURCE="$ROOT_DIR/Sources/OracleFreeKit/Resources/OracleFreeAppIcon.icns"
APP_ICON_PNG_SOURCE="$ROOT_DIR/Sources/OracleFreeKit/Resources/OracleFreeAppIcon.png"
DMG_STAGING_DIR="$DIST_DIR/dmg-root"
PACKAGE_IMAGE="$DIST_DIR/$APP_DISPLAY_NAME-$APP_VERSION.dmg"
LEGACY_PACKAGE_ARCHIVE="$DIST_DIR/$APP_DISPLAY_NAME-$APP_VERSION-unsigned.zip"

cd "$ROOT_DIR"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

swift build
BUILD_DIR="$(swift build --show-bin-path)"
BUILD_BINARY="$BUILD_DIR/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"
cp "$APP_ICON_SOURCE" "$APP_RESOURCES/OracleFreeAppIcon.icns"
cp "$APP_ICON_PNG_SOURCE" "$APP_RESOURCES/OracleFreeAppIcon.png"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>$APP_DISPLAY_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_DISPLAY_NAME</string>
  <key>CFBundleIconFile</key>
  <string>OracleFreeAppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_VERSION</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

/usr/bin/plutil -lint "$INFO_PLIST" >/dev/null
/usr/bin/codesign --force --deep --sign - "$APP_BUNDLE"
/usr/bin/codesign --verify --deep --strict "$APP_BUNDLE"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

package_app() {
  rm -f "$PACKAGE_IMAGE"
  rm -f "$LEGACY_PACKAGE_ARCHIVE"
  rm -rf "$DMG_STAGING_DIR"
  mkdir -p "$DMG_STAGING_DIR"
  /usr/bin/ditto "$APP_BUNDLE" "$DMG_STAGING_DIR/$APP_DISPLAY_NAME.app"
  /usr/bin/hdiutil create \
    -volname "$APP_DISPLAY_NAME" \
    -srcfolder "$DMG_STAGING_DIR" \
    -ov \
    -format UDZO \
    "$PACKAGE_IMAGE"
  rm -rf "$DMG_STAGING_DIR"
  echo "$PACKAGE_IMAGE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  --package|package)
    package_app
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify|--package]" >&2
    exit 2
    ;;
esac
