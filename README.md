# gz

A small bash CLI for common git housekeeping across repos: bootstrapping,
committing, tagging, squash-resetting history, and submodule management.

## Installation

```sh
curl -fsSL https://raw.githubusercontent.com/zharfanug/gz/latest/install.sh | sh
```

or, if `curl` isn't available:

```sh
wget -qO- https://raw.githubusercontent.com/zharfanug/gz/latest/install.sh | sh
```

The installer downloads `gz` into the current directory and then tries to
place it on your `PATH`:

- **as root** — copies it into `/usr/local/bin`
- **as a regular user** — copies it into `~/.local/bin`

If that target directory doesn't exist or isn't writable, the installer
warns instead of failing — you'll still have a runnable `./gz` in the
current directory to move into place yourself.

## Usage

```
Usage: gz <subcommand> [options] [args]

  init         bootstrap a git repo
  update       commit, tag 'latest', and push
  merge        squash all history into a single fresh commit
  tag          create/move a tag and push it
  submodule    manage git submodules

  --help, -h       show this help
  --version, -V    show version

Run 'gz <subcommand> --help' for subcommand-specific options.
```

### `gz init`

Initializes a git repository in the current directory (if one doesn't
already exist), renames the branch to `main`, and ensures `.gitignore` has
a standard set of entries at the top. Makes no commit and no push.

### `gz update [-y] [COMMIT_MESSAGE]`

The everyday loop: stages and commits all changes (default message:
`minor update`), force-moves the `latest` tag to the new commit, then
pushes `main` and force-pushes `latest` to `origin` — skipped silently if
no remote is configured.

### `gz merge [-y] [COMMIT_MESSAGE]`

**Destructive.** Collapses the entire repository history into a single
fresh commit (default message: `Initial commit`), force-moves `latest`,
and force-pushes `main` and `latest`. Prompts for confirmation unless `-y`
is passed — there is no undo once pushed.

### `gz tag [-y] TAG [MESSAGE]`

Deletes any existing local tag named `TAG`, then recreates it — annotated
if `MESSAGE` is given, lightweight otherwise — and force-pushes it to
`origin`.

### `gz submodule <action> [args]`

```
gz submodule add <url> <path> [branch]
gz submodule list
gz submodule rm <path>
gz submodule tags <path> [N]
gz submodule checkout <path> <ref>
```

`list` prints each submodule's path, pegged version, and URL. `rm` prompts
for confirmation before deiniting and removing. `checkout` only moves the
submodule's working tree — commit the pointer bump in the parent repo
yourself when you're ready.

## Requirements

- `bash`
- `git`

## Development

Source lives in `src/`, split one file per subcommand plus `00-lib.sh`
(shared helpers) and `zz-main.sh` (dispatcher) — concatenated in order at
build time.

```sh
git clone https://github.com/zharfanug/gz.git
cd gz
./tools/build.sh            # build dev-build/gz
dev-build/gz --help
./tools/build.sh --release  # bump VERSION, build dev-build/gz, commit,
                             # tag "latest", push (if a remote is
                             # configured), then upload dev-build/gz as
                             # a release asset on the "latest" tag
```

`VERSION` follows `MAJOR.MINOR.PATCH_TIMESTAMP` (e.g. `0.1.0_202611041408`);
`tools/update.sh` bumps it, `tools/build.sh --release` calls that
automatically. The binary is never committed — it's built fresh into the
gitignored `dev-build/` and shipped only as a release asset, which is why
`--release` additionally requires the [GitHub CLI](https://cli.github.com)
(`gh`), authenticated via `gh auth login`. Without it, `--release` still
commits/tags/pushes `VERSION` as normal, but warns and skips the asset
upload — run the command it prints manually, or install `gh` and re-run.

## License

MIT — see [LICENSE](LICENSE).
