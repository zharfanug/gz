#!/bin/sh

if [ -t 2 ]; then
  ESC=$(printf '\033')
  R="${ESC}[1;31m"
  Y="${ESC}[1;33m"
  C0="${ESC}[0m"
else
  R=
  Y=
  C0=
fi

log() {
  printf '%s\n' "$*"
}

log_warn() {
  printf "%bWARN: %s%b\n" "$Y" "$*" "$C0" >&2
}

log_error() {
  printf "%bERROR: %s%b\n" "$R" "$*" "$C0" >&2
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log_error "Required command not found: $1"
    exit 1
  fi
}

# Repo URL
REPO="zharfanug/gz"
GZ_URL="https://raw.githubusercontent.com/${REPO}/latest/gz"

BIN_FILE="gz"

# download URL OUTPUT — curl first, wget fallback, log_error on any failure.
download() {
  _url="$1"
  _output="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL --connect-timeout 5 --max-time 30 -o "$_output" "$_url"
    _rc=$?
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$_output" --timeout=5 --tries=1 "$_url"
    _rc=$?
  else
    log_error "Neither curl nor wget is available — please install one of them"
    return 1
  fi

  if [ "$_rc" -ne 0 ]; then
    log_error "Failed to download ${_url}"
  fi

  return "$_rc"
}

for _c in id mkdir chmod cp; do
  require_cmd "$_c"
done

log "Downloading ${GZ_URL}"
download "$GZ_URL" "./${BIN_FILE}" || exit 1
chmod +x "./${BIN_FILE}"
log "Downloaded to ./${BIN_FILE}"

if [ "$(id -u)" -eq 0 ]; then
  BIN_DIR="/usr/local/bin"
else
  BIN_DIR="${HOME}/.local/bin"
fi

if [ ! -d "$BIN_DIR" ]; then
  mkdir -p "$BIN_DIR" 2>/dev/null
fi

if [ ! -d "$BIN_DIR" ] || [ ! -w "$BIN_DIR" ]; then
  log_warn "Could not write to ${BIN_DIR} — leaving ./${BIN_FILE} in place"
  log_warn "Move it yourself, e.g.: mkdir -p ${BIN_DIR} && cp ./${BIN_FILE} ${BIN_DIR}/"
  if [ "$(id -u)" -ne 0 ]; then
    log_warn "Make sure ${BIN_DIR} is on your \$PATH"
  fi
  exit 0
fi

cp -f "./${BIN_FILE}" "${BIN_DIR}/${BIN_FILE}"
chmod +x "${BIN_DIR}/${BIN_FILE}"
log "Installed to ${BIN_DIR}/${BIN_FILE}"

if [ "$(id -u)" -ne 0 ]; then
  case ":$PATH:" in
    *":${BIN_DIR}:"*) ;;
    *) log_warn "${BIN_DIR} is not on your \$PATH — add it to use 'gz' directly" ;;
  esac
fi
