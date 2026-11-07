# My Git config

The config is separated in multiple topic files.

The idea is that every time I want my config, I'll want the general common configs + custom stuff.

To get started, `cp ./config.example ./config` and edit it with the relevant configs for your
directories and user(s) setup.


### Notes

**Why common are in dedicated dir instead of plainly in git folder?**
To be able to symlink the whole common dir, without the actual config entrypoint that is going to be
specific and shouldn't be common.

## Helper scripts

`bin/` holds small git helper scripts, exposed as `git <cmd>` subcommands
(the dir is added to `PATH` from `shell/env.sh`).

Listers (read-only, one path per line):

- `git tracked-new-files` — intent-to-add files and unstaged renames (`--raw`, `--json`).
- `git staged-files` — every path staged in the index.
- `git staged-new-files` — staged additions and rename destinations.
- `git staged-renamed-from-files` — source paths of staged renames.
- `git tracked-files` — every path recorded in the index.

Actions:

- `git unstage-keep-new` (alias: `git unstage`) — unstage the given paths, keeping
  new files as intent-to-add.
- `git unstage-new-files` — unstage only new files, keeping them intent-to-add.
- `git untrack-new-files` — drop intent-to-add and unstaged-rename entries from the index.
- `git better-rename` (alias: `git rename`) — move/rename files, unstaged by
  default; `--staged` records the move in the index, `--undo` reverses a move.
- `git untrack` — drop paths from the index, keeping them in the work tree (`rm --cached`).
- `git restore-from <rev>` — restore paths from a specific revision.

Aliases are defined in `common/_aliases.gitconfig`; zsh completions live in `zsh-completers/`
(added to `fpath` from `zsh/rc/completions.zsh`).

Tests: `bats bin/*.bats`, sharing helpers in `bin/_bats_helpers.sh`.
