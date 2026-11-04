#!/bin/bash
# --------------------- submodule.sh ---------------------
# `gz submodule` — manage git submodules in the current repo. Ported from
# references/old-script/submodule.sh.

cmd_submodule_usage() {
  printf '%s\n' "Usage: gz submodule <action> [args]"
  printf '\n'
  printf '%s\n' "  add <url> <path> [branch]   Add a new submodule."
  printf '%s\n' "  list                         List all submodules with their pegged version."
  printf '%s\n' "  rm <path>                    Remove a submodule (prompts for confirmation)."
  printf '%s\n' "  tags <path> [N]              List the N most recent tags for a submodule (default 20)."
  printf '%s\n' "  checkout <path> <ref>        Fetch and check out a tag/branch/commit in a submodule."
}

_submodule_require() {
  local _path=$1
  if [ ! -d "$_path" ]; then
    log_error "No such path: $_path"
    return 1
  fi
  if [ ! -d "$_path/.git" ] && [ ! -f "$_path/.git" ]; then
    log_error "$_path is not an initialized submodule. Run: git submodule update --init $_path"
    return 1
  fi
}

_submodule_pegged_version() {
  local _path=$1
  git -C "$_path" describe --tags --long 2>/dev/null \
    || git -C "$_path" rev-parse --short HEAD
}

_submodule_add() {
  local _url=${1:-} _path=${2:-} _branch=${3:-}
  if [ -z "$_url" ] || [ -z "$_path" ]; then
    log_error "Usage: gz submodule add <url> <path> [branch]"
    return 1
  fi
  if [ -n "$_branch" ]; then
    git submodule add -b "$_branch" "$_url" "$_path"
  else
    git submodule add "$_url" "$_path"
  fi
  printf '\n'
  printf '%s\n' "Added. Review and commit .gitmodules + $_path to finish:"
  printf '%s\n' "  git add .gitmodules $_path && git commit"
}

_submodule_list() {
  if [ ! -f .gitmodules ]; then
    printf '%s\n' "No submodules configured."
    return 0
  fi
  git submodule foreach --quiet '
    ref=$(git describe --tags --long 2>/dev/null || git rev-parse --short HEAD)
    url=$(git config --get remote.origin.url)
    printf "%-20s %-35s %s\n" "$sm_path" "$ref" "$url"
  '
}

_submodule_rm() {
  local _path=${1:-}
  if [ -z "$_path" ]; then
    log_error "Usage: gz submodule rm <path>"
    return 1
  fi
  _submodule_require "$_path" || return 1

  if ! confirm "This will deinit and remove the submodule at '$_path' (currently: $(_submodule_pegged_version "$_path")). Proceed?" n; then
    log "Operation cancelled"
    return 0
  fi

  git submodule deinit -f -- "$_path"
  git rm -f "$_path"
  rm -rf ".git/modules/$_path"

  printf '\n'
  printf '%s\n' "Removed. Review and commit .gitmodules to finish:"
  printf '%s\n' "  git commit -m 'Remove $_path submodule'"
}

_submodule_tags() {
  local _path=${1:-} _count=${2:-20}
  if [ -z "$_path" ]; then
    log_error "Usage: gz submodule tags <path> [N]"
    return 1
  fi
  _submodule_require "$_path" || return 1
  git -C "$_path" fetch --tags --quiet
  git -C "$_path" tag --sort=-creatordate | head -n "$_count"
}

_submodule_checkout() {
  local _path=${1:-} _ref=${2:-}
  if [ -z "$_path" ] || [ -z "$_ref" ]; then
    log_error "Usage: gz submodule checkout <path> <tag|branch|commit>"
    return 1
  fi
  _submodule_require "$_path" || return 1
  git -C "$_path" fetch --all --tags --quiet
  git -C "$_path" checkout "$_ref"
  printf '\n'
  printf '%s\n' "$_path is now at: $(_submodule_pegged_version "$_path")"
  printf '\n'
  printf '%s\n' "Note: this moves the submodule's checked-out commit locally only. Run" \
                "'git add $_path && git commit' in this repo to record the new" \
                "submodule pointer, if that's what you want."
}

cmd_submodule() {
  require_cmd git

  local _action=${1:-}
  case "$_action" in
    --help|-h|"")
      cmd_submodule_usage
      return 0
      ;;
  esac
  shift

  case "$_action" in
    add) _submodule_add "$@" ;;
    list) _submodule_list "$@" ;;
    rm) _submodule_rm "$@" ;;
    tags) _submodule_tags "$@" ;;
    checkout) _submodule_checkout "$@" ;;
    *)
      log_error "Unknown action: $_action"
      cmd_submodule_usage
      return 1
      ;;
  esac
}
