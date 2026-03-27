#!/usr/bin/env bash

VERSION_FILE_PATH="${VERSION_FILE_PATH:-$ROOT_DIR/VERSION}"
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
