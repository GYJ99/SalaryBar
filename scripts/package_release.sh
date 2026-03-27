#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
STAGING_DIR="$DIST_DIR/dmg-staging"
source "$ROOT_DIR/scripts/icon_support.sh"
source "$ROOT_DIR/scripts/version_support.sh"

APP_NAME="${APP_NAME:-SalaryBar}"
DISPLAY_NAME="${DISPLAY_NAME:-SalaryBar}"
BUNDLE_ID="${BUNDLE_ID:-com.guoyanjie.SalaryBar}"
VERSION="${VERSION:-}"
BUILD_NUMBER="${BUILD_NUMBER:-}"
MIN_MACOS_VERSION="${MIN_MACOS_VERSION:-13.0}"
RUN_TESTS="${RUN_TESTS:-0}"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
NOTARIZE="${NOTARIZE:-0}"
NOTARY_PROFILE="${NOTARY_PROFILE:-}"
TEAM_ID="${TEAM_ID:-}"

APP_PATH="$DIST_DIR/${APP_NAME}.app"
DMG_PATH=""

log() {
  printf '\033[1;32m[package]\033[0m %s\n' "$1"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

derive_version_info() {
  local commit_count=""
  local short_sha=""

  if has_cmd git && git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    commit_count="$(git -C "$ROOT_DIR" rev-list --count HEAD 2>/dev/null || true)"
    short_sha="$(git -C "$ROOT_DIR" rev-parse --short HEAD 2>/dev/null || true)"
  fi

  if [[ -z "$VERSION" ]]; then
    VERSION="$(read_config_version)"
  fi

  if [[ -z "$BUILD_NUMBER" ]]; then
    if [[ -n "$commit_count" ]]; then
      BUILD_NUMBER="$commit_count"
    else
      BUILD_NUMBER="1"
    fi
  fi

  DMG_PATH="$DIST_DIR/${APP_NAME}-${VERSION}.dmg"

  log "Version: $VERSION"
  log "Build: $BUILD_NUMBER${short_sha:+ ($short_sha)}"
}

build_app_bundle() {
  log "Building release binary"
  swift build -c release --package-path "$ROOT_DIR" --product "$APP_NAME"

  local bin_dir
  bin_dir="$(swift build -c release --package-path "$ROOT_DIR" --show-bin-path)"

  log "Creating app bundle"
  rm -rf "$APP_PATH"
  mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"

  cp "$bin_dir/$APP_NAME" "$APP_PATH/Contents/MacOS/$APP_NAME"
  chmod +x "$APP_PATH/Contents/MacOS/$APP_NAME"
  if install_app_icon "$APP_PATH"; then
    log "Installed app icon from Assets/AppIcon"
  else
    log "No icon sources found in Assets/AppIcon, skipping app icon"
  fi

  cat > "$APP_PATH/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh_CN</string>
    <key>CFBundleDisplayName</key>
    <string>${DISPLAY_NAME}</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>${ICON_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>${MIN_MACOS_VERSION}</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

  printf 'APPL????' > "$APP_PATH/Contents/PkgInfo"

  if [[ -n "$SIGN_IDENTITY" ]]; then
    log "Signing app with identity: $SIGN_IDENTITY"
    codesign --force --deep --options runtime --sign "$SIGN_IDENTITY" "$APP_PATH" >/dev/null
  else
    log "Applying ad-hoc code signature"
    codesign --force --deep --sign - "$APP_PATH" >/dev/null
  fi
}

build_dmg() {
  log "Packaging DMG"
  rm -rf "$STAGING_DIR"
  mkdir -p "$STAGING_DIR"

  cp -R "$APP_PATH" "$STAGING_DIR/"
  ln -s /Applications "$STAGING_DIR/Applications"
  if install_dmg_volume_icon "$STAGING_DIR"; then
    log "Installed DMG volume icon"
  else
    log "No icon sources found in Assets/AppIcon, skipping DMG volume icon"
  fi
  rm -f "$DMG_PATH"

  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

  rm -rf "$STAGING_DIR"
}

notarize_dmg() {
  if [[ "$NOTARIZE" != "1" ]]; then
    return
  fi

  require_cmd xcrun

  if [[ -z "$NOTARY_PROFILE" ]]; then
    echo "NOTARIZE=1 requires NOTARY_PROFILE to be set" >&2
    exit 1
  fi

  if [[ -z "$SIGN_IDENTITY" ]]; then
    echo "NOTARIZE=1 requires SIGN_IDENTITY to be set" >&2
    exit 1
  fi

  log "Submitting DMG for notarization"
  xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

  log "Stapling notarization ticket"
  xcrun stapler staple "$DMG_PATH"
}

main() {
  require_cmd swift
  require_cmd codesign
  require_cmd hdiutil
  derive_version_info

  mkdir -p "$DIST_DIR"
  sync_readme_version "$VERSION"

  if [[ "$RUN_TESTS" == "1" ]]; then
    log "Running tests"
    swift test --package-path "$ROOT_DIR"
  else
    log "Skipping tests because RUN_TESTS=$RUN_TESTS"
  fi

  build_app_bundle
  build_dmg
  notarize_dmg

  log "Done"
  echo "APP: $APP_PATH"
  echo "DMG: $DMG_PATH"
}

main "$@"
