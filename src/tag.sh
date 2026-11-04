#!/bin/bash
# --------------------- tag.sh ---------------------
# `gz tag` — create/move a tag and push it. Ported from
# references/old-script/git-tag-update.sh.

cmd_tag_usage() {
  printf '%s\n' "Usage: gz tag [-y] TAG [MESSAGE]"
  printf '\n'
  printf '%s\n' "  -y    skip confirmation prompt"
  printf '\n'
  printf '%s\n' "Deletes any existing local tag named TAG, then recreates it — annotated"
  printf '%s\n' "(-a -m MESSAGE) if MESSAGE is given, lightweight otherwise — and"
  printf '%s\n' "force-pushes it to origin (skipped silently if no remote)."
}

cmd_tag() {
  require_cmd git

  SKIP_PROMPT=false
  local _args=()
  local _arg
  for _arg in "$@"; do
    case "$_arg" in
      --help|-h)
        cmd_tag_usage
        return 0
        ;;
      -y)
        SKIP_PROMPT=true
        ;;
      -*)
        log_error "Unknown option: $_arg"
        cmd_tag_usage
        return 1
        ;;
      *)
        _args+=("$_arg")
        ;;
    esac
  done

  local _tag=${_args[0]:-}
  local _tag_message=${_args[1]:-}

  if [ -z "$_tag" ]; then
    log_error "Missing required argument: TAG"
    cmd_tag_usage
    return 1
  fi

  if ! confirm "Create tag '$_tag'?"; then
    log "Operation cancelled"
    return 0
  fi

  git tag -d "$_tag" >/dev/null 2>&1 || true

  if [ -n "$_tag_message" ]; then
    log "Creating annotated tag '$_tag'"
    git tag -a "$_tag" -m "$_tag_message"
  else
    log "Creating tag '$_tag'"
    git tag "$_tag"
  fi

  push_remote "$_tag" --force

  log "Done"
}
