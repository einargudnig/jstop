#!/usr/bin/env bash
set -euo pipefail

# Build a fresh Release of jstop and install it into /Applications, replacing
# any older copy. Run this instead of leaving /Applications to drift behind the
# source — a stale install only knows how to draw the older UI.

# ─── Configuration ───────────────────────────────────────────────────────────
APP_NAME="jstop"
SCHEME="jstop"
PROJECT="${APP_NAME}.xcodeproj"

BUILD_DIR="build"
DERIVED_DATA="${BUILD_DIR}/Build/.."
BUILT_APP="${BUILD_DIR}/Build/Products/Release/${APP_NAME}.app"
INSTALL_PATH="/Applications/${APP_NAME}.app"

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

# Run from the repo root regardless of where the script is invoked from.
cd "$(dirname "$0")/.."

# ─── Build ───────────────────────────────────────────────────────────────────
blue "▸ Building ${APP_NAME} (Release)…"

xcodebuild \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -derivedDataPath "${DERIVED_DATA}" \
  build \
  | tail -1

[ -d "${BUILT_APP}" ] || die ".app not found at ${BUILT_APP}"
green "✓ Build succeeded"

# ─── Install ─────────────────────────────────────────────────────────────────
blue "▸ Installing to ${INSTALL_PATH}…"

# Quit any running copy so the bundle isn't in use while we replace it.
osascript -e "tell application \"${APP_NAME}\" to quit" >/dev/null 2>&1 || true
pkill -x "${APP_NAME}" >/dev/null 2>&1 || true
sleep 1

rm -rf "${INSTALL_PATH}"
cp -R "${BUILT_APP}" "${INSTALL_PATH}"
green "✓ Installed"

# ─── Launch ──────────────────────────────────────────────────────────────────
open "${INSTALL_PATH}"
green "✓ Launched ${APP_NAME}"
