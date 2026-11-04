#!/bin/bash
# --------------------- update.sh ---------------------
# `gz update` — the everyday "commit and publish" loop.
# Ported from references/old-script/git-update.sh.

cmd_update_usage() {
  printf '%s\n' "Usage: gz update [-y] [COMMIT_MESSAGE]"
  printf '\n'
  printf '%s\n' "  -y    skip confirmation prompt"
  printf '\n'
  printf '%s\n' "Stages and commits all changes (default message: \"minor update\"),"
  printf '%s\n' "force-moves the 'latest' tag to the new commit, then pushes main and"
  printf '%s\n' "force-pushes 'latest' to origin (skipped silently if no remote)."
}

cmd_update() {
  require_cmd git

  SKIP_PROMPT=false
  local _args=()
  local _arg
  for _arg in "$@"; do
    case "$_arg" in
      --help|-h)
        cmd_update_usage
        return 0
        ;;
      -y)
        SKIP_PROMPT=true
        ;;
      -*)
        log_error "Unknown option: $_arg"
        cmd_update_usage
        return 1
        ;;
      *)
        _args+=("$_arg")
        ;;
    esac
  done

  local _commit_message=${_args[0]:-minor update}

  check_git_identity

  if [ ! -d .git ]; then
    log "Initializing new git repository"
    git init -b main
  fi

  local _changes
  _changes="$(git status --porcelain)"

  if [ -z "$_changes" ]; then
    log_warn "Nothing to commit"
    return 0
  fi

  log "Changed files:"
  git status --short

  if ! confirm "Commit these changes?"; then
    log "Operation cancelled"
    return 0
  fi

  git add -A
  git commit -m "$_commit_message"

  log "Tagging latest commit as 'latest'"
  git tag -f latest

  push_remote main
  push_remote latest --force

  log "Done"
}
