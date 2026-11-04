#!/bin/bash
# --------------------- merge.sh ---------------------
# `gz merge` — destructive history squash: collapses the entire repo
# history into a single fresh commit. Ported from
# references/old-script/git-merge.sh.

cmd_merge_usage() {
  printf '%s\n' "Usage: gz merge [-y] [COMMIT_MESSAGE]"
  printf '\n'
  printf '%s\n' "  -y    skip confirmation prompt"
  printf '\n'
  printf '%s\n' "WARNING: this deletes all git history. Resets the repo to a single"
  printf '%s\n' "fresh commit (default message: \"Initial commit\"), force-moves the"
  printf '%s\n' "'latest' tag to it, then force-pushes main and 'latest' to origin"
  printf '%s\n' "(skipped silently if no remote)."
}

cmd_merge() {
  require_cmd git

  SKIP_PROMPT=false
  local _args=()
  local _arg
  for _arg in "$@"; do
    case "$_arg" in
      --help|-h)
        cmd_merge_usage
        return 0
        ;;
      -y)
        SKIP_PROMPT=true
        ;;
      -*)
        log_error "Unknown option: $_arg"
        cmd_merge_usage
        return 1
        ;;
      *)
        _args+=("$_arg")
        ;;
    esac
  done

  local _commit_message=${_args[0]:-Initial commit}

  check_git_identity

  if [ ! -d .git ]; then
    log "Initializing new git repository"
    git init -b main
  else
    if ! confirm "${Y}WARNING: this will delete all git history. Continue?${C0}" n; then
      log "Operation cancelled"
      return 0
    fi

    log "Creating temporary orphan branch"
    git checkout --orphan merge-reset-temp

    log "Removing old tracked files"
    git rm -rf --cached . >/dev/null 2>&1 || true

    log "Removing old branch history"
    git branch -D main >/dev/null 2>&1 || true

    log "Renaming temporary branch to main"
    git branch -M main
  fi

  log "Adding all current files"
  git add -A

  if git diff --cached --quiet; then
    log_warn "Nothing to commit"
    return 0
  fi

  log "Creating initial commit"
  git commit -m "$_commit_message"
  git branch -M main

  log "Tagging latest commit as 'latest'"
  git tag -f latest

  push_remote main --force
  push_remote latest --force

  log "Done"
}
