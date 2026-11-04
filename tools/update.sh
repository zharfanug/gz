#!/bin/sh

SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
WORKSPACE_DIR=$(dirname "$SCRIPT_DIR")

cd "$WORKSPACE_DIR" || exit 1

VER_FILE="VERSION"

# Bumps the patch part of "MAJOR.MINOR.PATCH_TIMESTAMP" and refreshes the
# timestamp, e.g. "0.1.0_202611041408" -> "0.1.1_202611051950".
update_ver() {
  _current=$(cut -d'_' -f1 "$VER_FILE")

  IFS='.' read -r _major _minor _patch <<EOF
$_current
EOF

  _patch=$((_patch + 1))
  _new="${_major}.${_minor}.${_patch}_$(date +'%Y%m%d%H%M')"

  printf '%s' "$_new" > "$VER_FILE"
  printf 'Version bumped: %s -> %s\n' "$_current" "$_new"
}

update_ver
