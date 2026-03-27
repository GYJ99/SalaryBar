#!/usr/bin/env bash

ICON_ASSET_DIR="${ICON_ASSET_DIR:-$ROOT_DIR/Assets/AppIcon}"
ICON_SOURCE_SVG="${ICON_SOURCE_SVG:-$ICON_ASSET_DIR/app_icon.svg}"
ICON_NAME="${ICON_NAME:-AppIcon}"
ICON_PREBUILT_ICNS="${ICON_PREBUILT_ICNS:-$ICON_ASSET_DIR/${ICON_NAME}.icns}"
GENERATED_ICON_PATH=""

has_icon_sources() {
  [[ -f "$ICON_PREBUILT_ICNS" || -f "$ICON_SOURCE_SVG" ]]
}

render_from_svg() {
  local size="$1"
  local output_path="$2"
  local module_cache_dir="${DIST_DIR:-$ROOT_DIR/dist}/.icon-build/module-cache"

  mkdir -p "$module_cache_dir"
  swift -module-cache-path "$module_cache_dir" \
    "$ROOT_DIR/scripts/render_svg_icon.swift" "$ICON_SOURCE_SVG" "$output_path" "$size" >/dev/null
}

render_icon_png() {
  local size="$1"
  local output_path="$2"

  render_from_svg "$size" "$output_path"
}

build_app_icon() {
  if [[ -n "$GENERATED_ICON_PATH" && -f "$GENERATED_ICON_PATH" ]]; then
    return 0
  fi

  if ! has_icon_sources; then
    return 1
  fi

  if [[ -f "$ICON_PREBUILT_ICNS" ]]; then
    GENERATED_ICON_PATH="$ICON_PREBUILT_ICNS"
    return 0
  fi

  local icon_work_dir="${DIST_DIR:-$ROOT_DIR/dist}/.icon-build"
  local iconset_dir="$icon_work_dir/${ICON_NAME}.iconset"
  local output_path="$icon_work_dir/${ICON_NAME}.icns"

  rm -rf "$icon_work_dir"
  mkdir -p "$iconset_dir"

  render_icon_png 16 "$iconset_dir/icon_16x16.png"
  render_icon_png 32 "$iconset_dir/icon_16x16@2x.png"
  render_icon_png 32 "$iconset_dir/icon_32x32.png"
  render_icon_png 64 "$iconset_dir/icon_32x32@2x.png"
  render_icon_png 128 "$iconset_dir/icon_128x128.png"
  render_icon_png 256 "$iconset_dir/icon_128x128@2x.png"
  render_icon_png 256 "$iconset_dir/icon_256x256.png"
  render_icon_png 512 "$iconset_dir/icon_256x256@2x.png"
  render_icon_png 512 "$iconset_dir/icon_512x512.png"
  render_icon_png 1024 "$iconset_dir/icon_512x512@2x.png"

  iconutil -c icns "$iconset_dir" -o "$output_path"
  GENERATED_ICON_PATH="$output_path"
}

install_app_icon() {
  local app_path="$1"

  if ! build_app_icon; then
    return 1
  fi

  mkdir -p "$app_path/Contents/Resources"
  cp "$GENERATED_ICON_PATH" "$app_path/Contents/Resources/${ICON_NAME}.icns"
}

install_dmg_volume_icon() {
  local staging_dir="$1"

  if ! build_app_icon; then
    return 1
  fi

  cp "$GENERATED_ICON_PATH" "$staging_dir/.VolumeIcon.icns"
  SetFile -a V "$staging_dir/.VolumeIcon.icns"
  SetFile -a C "$staging_dir"
}
