#!/bin/bash
# --------------------- 99-main.sh ---------------------
# Top-level argument parsing and subcommand dispatch.

GZ_SUBCOMMANDS="init update merge tag submodule"

print_usage() {
  printf '%s\n' "Usage: gz <subcommand> [options] [args]"
  printf '\n'
  printf '%s\n' "  init         bootstrap a git repo"
  printf '%s\n' "  update       commit, tag 'latest', and push"
  printf '%s\n' "  merge        squash all history into a single fresh commit"
  printf '%s\n' "  tag          create/move a tag and push it"
  printf '%s\n' "  submodule    manage git submodules"
  printf '\n'
  printf '%s\n' "  --help, -h       show this help"
  printf '%s\n' "  --version, -V    show version"
  printf '\n'
  printf '%s\n' "Run 'gz <subcommand> --help' for subcommand-specific options."
}

print_version() {
  printf 'gz %s\n' "$GZ_VERSION"
}

main() {
  if [ "$#" -eq 0 ]; then
    print_usage
    return 1
  fi

  local _subcommand=$1
  shift

  case "$_subcommand" in
    --help|-h)
      print_usage
      return 0
      ;;
    --version|-V)
      print_version
      return 0
      ;;
    init) cmd_init "$@" ;;
    update) cmd_update "$@" ;;
    merge) cmd_merge "$@" ;;
    tag) cmd_tag "$@" ;;
    submodule) cmd_submodule "$@" ;;
    *)
      log_error "Unknown subcommand: $_subcommand"
      print_usage
      return 1
      ;;
  esac
}

main "$@"
