#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
ICON_PREBUILT_ICNS="$DIST_DIR/.icon-build/skip-prebuilt.icns"
source "$ROOT_DIR/scripts/icon_support.sh"

OUTPUT_ICNS="$ROOT_DIR/Assets/AppIcon/${ICON_NAME}.icns"

mkdir -p "$DIST_DIR"
build_app_icon
cp -f "$GENERATED_ICON_PATH" "$OUTPUT_ICNS"

echo "$OUTPUT_ICNS"
