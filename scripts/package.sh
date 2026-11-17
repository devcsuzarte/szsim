#!/usr/bin/env bash
#
# Package SZSIM as a distributable .dmg.
#
# Universal (arm64 + x86_64), ad-hoc signed ("Sign to Run Locally"), NOT notarized
# (no paid Apple Developer account needed). Recipients remove the quarantine on first
# launch — see README / the printed instructions.
#
set -euo pipefail

cd "$(dirname "$0")/.."

SCHEME="SZSIM"
APP_NAME="SZSIM"
DERIVED="build"
RELEASE_APP="$DERIVED/Build/Products/Release/$APP_NAME.app"
DIST="dist"
DMG="$DIST/$APP_NAME.dmg"

echo "==> Building universal Release (ad-hoc signed)..."
xcodebuild -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$DERIVED" \
  ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="" PROVISIONING_PROFILE_SPECIFIER="" \
  clean build

echo "==> Re-signing ad-hoc (idempotent)..."
codesign --force --options runtime --sign - "$RELEASE_APP"
codesign --verify --strict --verbose=2 "$RELEASE_APP"

echo "==> Architectures:"
lipo -archs "$RELEASE_APP/Contents/MacOS/$APP_NAME"

echo "==> Creating $DMG..."
mkdir -p "$DIST"
rm -f "$DMG"
STAGE="$(mktemp -d)"
cp -R "$RELEASE_APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
rm -rf "$STAGE"

echo "==> Verifying dmg..."
hdiutil verify "$DMG" >/dev/null && echo "dmg OK"

echo
echo "==> Done: $DMG"
echo "    Install: open the .dmg, drag SZSIM to Applications."
echo "    First launch on another Mac (not notarized):"
echo "      right-click SZSIM → Open → Open,  or"
echo "      xattr -dr com.apple.quarantine /Applications/SZSIM.app"
