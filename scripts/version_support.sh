#!/usr/bin/env bash

VERSION_FILE_PATH="${VERSION_FILE_PATH:-$ROOT_DIR/VERSION}"
README_PATH="${README_PATH:-$ROOT_DIR/README.md}"

read_config_version() {
  if [[ ! -f "$VERSION_FILE_PATH" ]]; then
    echo "Missing version file: $VERSION_FILE_PATH" >&2
    return 1
  fi

  local version
  version="$(tr -d '[:space:]' < "$VERSION_FILE_PATH")"
  if [[ -z "$version" ]]; then
    echo "Version file is empty: $VERSION_FILE_PATH" >&2
    return 1
  fi

  printf '%s' "$version"
}

sync_readme_version() {
  local version="$1"

  if [[ ! -f "$README_PATH" ]]; then
    return 0
  fi

  VERSION="$version" perl -0pi -e 's/<!-- VERSION:START -->.*?<!-- VERSION:END -->/<!-- VERSION:START -->当前版本：`$ENV{VERSION}`<!-- VERSION:END -->/s' "$README_PATH"
}
