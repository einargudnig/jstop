#!/usr/bin/env bash
set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────
APP_NAME="jstop"
SCHEME="jstop"
PROJECT="${APP_NAME}.xcodeproj"
BUNDLE_ID="com.jstop.jstop"
TEAM_ID="7AWFJS2W5C"

BUILD_DIR="build"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"
APP_PATH="${EXPORT_PATH}/${APP_NAME}.app"
DMG_PATH="${BUILD_DIR}/${APP_NAME}.dmg"
ZIP_PATH="${BUILD_DIR}/${APP_NAME}.zip"

# ─── Helpers ─────────────────────────────────────────────────────────────────
red()   { printf '\033[1;31m%s\033[0m\n' "$*"; }
green() { printf '\033[1;32m%s\033[0m\n' "$*"; }
blue()  { printf '\033[1;34m%s\033[0m\n' "$*"; }

die() { red "ERROR: $*" >&2; exit 1; }

require() {
  command -v "$1" >/dev/null 2>&1 || die "'$1' is required but not installed. $2"
}

# ─── Preflight ───────────────────────────────────────────────────────────────
require xcodebuild "Install Xcode."
require xcrun       "Install Xcode Command Line Tools."
require create-dmg  "Install with: brew install create-dmg"

# Apple ID for notarization — prefer env vars, fall back to keychain profile
NOTARY_PROFILE="${NOTARY_PROFILE:-jstop}"

blue "▸ Building ${APP_NAME} release…"

# ─── Clean & Archive ────────────────────────────────────────────────────────
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

xcodebuild archive \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -archivePath "${ARCHIVE_PATH}" \
  CODE_SIGN_IDENTITY="Developer ID Application" \
  DEVELOPMENT_TEAM="${TEAM_ID}" \
  CODE_SIGN_STYLE=Manual \
  OTHER_CODE_SIGN_FLAGS="--timestamp" \
  | tail -1

green "✓ Archive created"

# ─── Export .app ─────────────────────────────────────────────────────────────
EXPORT_PLIST="${BUILD_DIR}/export-options.plist"
cat > "${EXPORT_PLIST}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>${TEAM_ID}</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Developer ID Application</string>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
  -archivePath "${ARCHIVE_PATH}" \
  -exportPath "${EXPORT_PATH}" \
  -exportOptionsPlist "${EXPORT_PLIST}" \
  | tail -1

[ -d "${APP_PATH}" ] || die ".app not found at ${APP_PATH}"
green "✓ Exported ${APP_NAME}.app"

# ─── Notarize the .app (inside a zip) ───────────────────────────────────────
blue "▸ Notarizing ${APP_NAME}.app…"

ditto -c -k --keepParent "${APP_PATH}" "${ZIP_PATH}"

xcrun notarytool submit "${ZIP_PATH}" \
  --keychain-profile "${NOTARY_PROFILE}" \
  --wait

green "✓ App notarized"

# ─── Staple the .app ────────────────────────────────────────────────────────
xcrun stapler staple "${APP_PATH}"
green "✓ App stapled"

# ─── Create DMG ─────────────────────────────────────────────────────────────
blue "▸ Creating DMG…"

# Remove any previous DMG (create-dmg won't overwrite)
rm -f "${DMG_PATH}"

ICON_FLAG=()
if [ -f "${APP_PATH}/Contents/Resources/AppIcon.icns" ]; then
  ICON_FLAG=(--volicon "${APP_PATH}/Contents/Resources/AppIcon.icns")
fi

create-dmg \
  --volname "${APP_NAME}" \
  "${ICON_FLAG[@]}" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "${APP_NAME}.app" 150 190 \
  --hide-extension "${APP_NAME}.app" \
  --app-drop-link 450 190 \
  "${DMG_PATH}" \
  "${APP_PATH}" \
  || true  # create-dmg exits 2 when it can't set a background image — that's fine

[ -f "${DMG_PATH}" ] || die "DMG was not created"
green "✓ DMG created"

# ─── Notarize the DMG ───────────────────────────────────────────────────────
blue "▸ Notarizing DMG…"

xcrun notarytool submit "${DMG_PATH}" \
  --keychain-profile "${NOTARY_PROFILE}" \
  --wait

xcrun stapler staple "${DMG_PATH}"
green "✓ DMG notarized and stapled"

# ─── Verify ─────────────────────────────────────────────────────────────────
blue "▸ Verifying…"
spctl -a -vvv -t install "${APP_PATH}"
spctl -a -vvv -t install "${DMG_PATH}"
green "✓ Gatekeeper verification passed"

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
green "═══════════════════════════════════════"
green "  Release artifacts ready:"
green "    ${DMG_PATH}"
green "    ${ZIP_PATH}"
green "═══════════════════════════════════════"
echo ""
blue "To upload to a GitHub release:"
echo "  gh release create v1.x --title 'jstop v1.x' ${DMG_PATH} ${ZIP_PATH}"
