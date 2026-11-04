#!/bin/bash
# --------------------- 00-lib.sh ---------------------
# Shared logging, colors, and command-checking helpers used by every
# subcommand. Ported from the common header duplicated across all of
# references/old-script/*.sh.

GZ_VERSION="dev"

if [ -t 2 ]; then
  ESC=$(printf '\033')

  W="${ESC}[0;39m"
  R="${ESC}[1;31m"
  G="${ESC}[1;32m"
  Y="${ESC}[1;33m"
  B="${ESC}[1;34m"
  DIM="${ESC}[2m"
  C0="${ESC}[0m"
else
  W=
  R=
  G=
  Y=
  B=
  DIM=
  C0=
fi

log_format() {
  local _level=$1
  shift

  local _ts _msg _print _fd
  _ts=$(date '+%Y-%m-%d %H:%M:%S %z')
  _msg="$_ts - $_level : $*"

  case $_level in
    INFO)
      _print=$_msg
      _fd=1
      ;;
    WARN)
      _print="$_ts - ${Y}WARN${C0} : $*"
      _fd=2
      ;;
    ERROR)
      _print="$_ts - ${R}ERROR${C0} : $*"
      _fd=2
      ;;
    *)
      _print=$_msg
      _fd=1
      ;;
  esac

  printf '%b\n' "$_print" >&"$_fd"
}

log() {
  log_format INFO "$@"
}

log_warn() {
  log_format WARN "$@"
}

log_error() {
  log_format ERROR "$@"
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log_error "Required command not found: $1"
    exit 1
  fi
}

require_cmd_list() {
  local cmd
  for cmd in "$@"; do
    require_cmd "$cmd"
  done
}

# confirm PROMPT [DEFAULT] — DEFAULT is "y" (default) or "n". Honors the
# subcommand-local $SKIP_PROMPT (set by -y) to bypass the prompt entirely.
confirm() {
  local _prompt=$1
  local _default=${2:-y}

  if [ "${SKIP_PROMPT:-false}" = "true" ]; then
    return 0
  fi

  if [ "$_default" = "n" ]; then
    printf "%s (y/N): " "$_prompt"
  else
    printf "%s (Y/n): " "$_prompt"
  fi

  local _answer
  read -r _answer

  if [ "$_default" = "n" ]; then
    case "$_answer" in
      y|Y) return 0 ;;
      *) return 1 ;;
    esac
  else
    case "$_answer" in
      n|N) return 1 ;;
      *) return 0 ;;
    esac
  fi
}

check_git_identity() {
  local _name _email
  _name="$(git config user.name)"
  _email="$(git config user.email)"

  if [ -z "$_name" ] || [ -z "$_email" ]; then
    log_error "Git user.name and user.email must be configured before committing"
    log_error "Run: git config --global user.name \"Your Name\""
    log_error "Run: git config --global user.email \"you@example.com\""
    exit 1
  fi
}

# push_remote REF [--force] — pushes REF (branch or tag) to origin if it's
# configured and reachable; warns (never fails the caller) otherwise.
push_remote() {
  local _ref=$1
  local _force=${2:-}

  if ! git remote get-url origin >/dev/null 2>&1; then
    log "No origin remote found, skipping push"
    return 0
  fi

  log "Checking origin remote access"

  if ! git ls-remote origin >/dev/null 2>&1; then
    log_warn "Origin remote is not accessible"
    log_warn "Fix credentials or remote access, then push manually:"
    log_warn "git push ${_force:+--force }origin $_ref"
    return 0
  fi

  log "Pushing '$_ref' to origin"

  if ! git push ${_force:+--force} origin "$_ref"; then
    log_warn "Push failed"
    log_warn "Fix credentials or remote access, then run:"
    log_warn "git push ${_force:+--force }origin $_ref"
  fi
}
