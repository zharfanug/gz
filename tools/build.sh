#!/bin/sh

SCRIPT_NAME=$(basename "$0")
SCRIPT_PATH=$(realpath "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
WORKSPACE_DIR=$(dirname "$SCRIPT_DIR")

cd "$WORKSPACE_DIR" || exit 1

SRC_DIR="src"
BUILD_DIR="dev-build"
BUILD_FILE="gz"
RELEASE=false

print_usage() {
  printf '%s\n' "Usage: $SCRIPT_NAME [OPTION]"
  printf '\n'
  printf '%s\n' "  --help          show help"
  printf '%s\n' "  --release       bump version and build gz at the repo root, commit, tag, push"
  printf '\n'
  printf '%s\n' "With no option, builds ${BUILD_DIR}/${BUILD_FILE}."
}

# cat concatenates src/*.sh back-to-back with nothing in between, so a file
# missing its trailing newline merges its last line into the next file's
# first line and silently corrupts the build.
check_src_newlines() {
  for _f in "${SRC_DIR}"/*.sh; do
    if [ -n "$(tail -c1 "$_f")" ]; then
      printf 'WARN: %s does not end with a newline — fixing\n' "$_f" >&2
      printf '\n' >> "$_f"
    fi
  done
}

build_gz() {
  printf 'Reading source from %s/\n' "$SRC_DIR"

  check_src_newlines

  _ver=$(cat VERSION)
  printf 'Version: %s\n' "$_ver"

  mkdir -p "$BUILD_DIR"
  printf 'Concatenating %s/*.sh -> %s/%s\n' "$SRC_DIR" "$BUILD_DIR" "$BUILD_FILE"
  cat "${SRC_DIR}"/*.sh > "${BUILD_DIR}/${BUILD_FILE}"

  printf 'Patching GZ_VERSION\n'
  sed -i "s|^GZ_VERSION=.*|GZ_VERSION=\"${_ver}\"|" "${BUILD_DIR}/${BUILD_FILE}"

  chmod +x "${BUILD_DIR}/${BUILD_FILE}"
  printf 'Build complete: %s/%s\n' "$BUILD_DIR" "$BUILD_FILE"
}

# Commits VERSION + the built executable (using gz's own `update`
# subcommand, by running the just-built binary against its own repo rather
# than duplicating git calls here), moves the "latest" tag, and pushes.
release_publish() {
  _ver=$(cat VERSION)
  "./${BUILD_FILE}" update -y "$_ver"
}

for _arg do
  case "$_arg" in
    --help)
      print_usage
      exit 0
      ;;
    --release)
      RELEASE=true
      ;;
    *)
      printf '%s\n' "Unknown option: $_arg. Use --help for usage." >&2
      exit 1
      ;;
  esac
done

if [ "$RELEASE" = "true" ]; then
  printf 'Release build: bumping version\n'
  ./tools/update.sh
  BUILD_DIR="$WORKSPACE_DIR"
fi

build_gz

if [ "$RELEASE" = "true" ]; then
  release_publish
fi
