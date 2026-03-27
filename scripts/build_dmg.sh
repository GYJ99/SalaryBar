#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
STAGING_DIR="$DIST_DIR/dmg-staging"
DMG_PATH="$DIST_DIR/SalaryBar.dmg"
source "$ROOT_DIR/scripts/icon_support.sh"

"$ROOT_DIR/scripts/build_app.sh" >/dev/null

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$DIST_DIR/SalaryBar.app" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"
install_dmg_volume_icon "$STAGING_DIR" || true
rm -f "$DMG_PATH"

hdiutil create \
  -volname "SalaryBar" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

rm -rf "$STAGING_DIR"

echo "$DMG_PATH"
