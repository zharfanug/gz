#!/bin/bash
# --------------------- init.sh ---------------------
# `gz init` — lightweight, non-destructive repo bootstrap.
# Ported from references/old-script/git-init.sh.

GZ_INIT_GITIGNORE_ENTRIES='.*/
!.gitignore
.env
*.code-workspace'

cmd_init_usage() {
  printf '%s\n' "Usage: gz init"
  printf '\n'
  printf '%s\n' "Initializes a git repository in the current directory (if one doesn't"
  printf '%s\n' "already exist), renames the branch to 'main', and ensures .gitignore"
  printf '%s\n' "has the standard entries at the top. Makes no commit and no push."
}

cmd_init() {
  for _arg in "$@"; do
    case "$_arg" in
      --help|-h)
        cmd_init_usage
        return 0
        ;;
      *)
        log_error "Unknown option: $_arg"
        cmd_init_usage
        return 1
        ;;
    esac
  done

  require_cmd git

  if [ ! -d .git ]; then
    log "Initializing git repository"
    git init .
    log "Renaming branch to main"
    git branch -m main
  else
    log "Git repository already initialized, skipping git init"
  fi

  if [ -f .gitignore ]; then
    log "Adding default entries to top of existing .gitignore"
    local _tmp
    _tmp=$(mktemp)
    printf '%s\n' "$GZ_INIT_GITIGNORE_ENTRIES" >"$_tmp"
    cat .gitignore >>"$_tmp"
    mv "$_tmp" .gitignore
  else
    log "Creating .gitignore"
    printf '%s\n' "$GZ_INIT_GITIGNORE_ENTRIES" >.gitignore
  fi

  log "Done"
}
