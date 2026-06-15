# Storage Layout

## Structure

Each Storage Dir (Local or Global): one subdir per Level containing Item files, plus an optional `config.yaml`.

```
<storage-dir>/
├── config.yaml              ← optional; Local only (see Config section)
├── next/
│   ├── 20260613T142301-fix-broken-symlink.md
│   └── 20260613T150000-try-nu-table-output.md
├── soon/
│   └── 20260614T090000-spec-later-scope-system.md
├── someday/
└── maybe/
```

Level dirs created on first use; empty level dir is valid.
Global Storage Dir does not use `config.yaml` — config is per Local Storage Dir only.

## Storage Dir types

### Local Storage Dir

Placement by context:

- **Git repo**: `.later-tasks/` at git repo root (`git rev-parse --show-toplevel`).
  Shared across all worktrees — always at shared git root, never per-worktree.
- **Non-git dir**: `.later-tasks/` at cwd.

`later` checks for git repo first; falls back to cwd.

#### Symlink mode (opt-in)

Local `.later-tasks/` may be a symlink into a subdirectory of the Global Storage Dir.
In this mode, all items physically live in global storage — local dir is a navigation shortcut.

Benefits:
- Single backup/sync target: only Global Storage Dir needs to be backed up.
- `later ls all` / `later status` work without scanning repo roots — everything already in global dir.

Tradeoff: `.later-tasks/` can't be committed to version control (symlink target is user-specific path).

Setup: user creates the symlink manually (or via `later init --link`).
`later` detects symlink transparently — no behavioral difference once resolved.

NOTE: subdir naming convention inside Global Storage Dir for symlink targets is unresolved.
See Open Questions in [SPEC.md](SPEC.md#open-questions).

### Global Storage Dir

Default: `$XDG_DATA_HOME/later-tasks/` (typically `~/.local/share/later-tasks/`).
Override via `$LATER_GLOBAL_STORAGE_DIR`.
Used when item has `@global` scope, or when adding outside any repo/dir context.
Also read in `later ls` here view (globally relevant items always shown).
`ls all` also reads this dir.

## Resolution

### At add-time

1. If item text contains `@global` → write to Global Storage Dir.
2. Else detect git root via `git rev-parse --show-toplevel`.
   - Found → Local = `<git-root>/.later-tasks/`.
   - Not found → check for `<cwd>/.later-tasks/`.
     - Exists → use it.
     - Not exists + not in repo → write to Global Storage Dir (auto-scope becomes `@global`).

### At list-time

| `ls` variant | Sources read |
|---|---|
| `ls` (default / here) | Local filtered to Active Scope + Global Storage Dir (`@global` always shown) |
| `ls repo` | Full Local (all scopes) + Global filtered to repo scope |
| `ls all` | All Storage Dirs, no scope filtering |

See [cli.md](cli.md#ls-variants) for full `ls` reference.

## Config

Local Storage Dir may contain `config.yaml` to declare project-level defaults and scope mappings.
Config is loaded when `later` resolves the Local Storage Dir for the current context.
Absence of `config.yaml` is valid — all fields are optional.

### Fields

```yaml
# Scope aliases: short tokens that expand to canonical scope names.
# Applied during add-time @-token extraction and ls-time filtering.
scope_aliases:
  nv: nvim
  plug: plugin

# Scope map: map cwd subpath prefixes to additional auto-scopes.
# All matching prefixes applied (additive, not exclusive).
# Paths relative to the git root (or Storage Dir parent for non-git).
scope_map:
  nvim/:        [@nvim]
  nvim/plugin/: [@nvim, @plugin]
  zsh/:         [@zsh]

# Ignore scopes: scopes hidden from `later ls` here/repo views by default.
# Still appear in `ls all`. User can override with --show-ignored.
ignore_scopes: [@plugin, @wip]
```

### Scope alias resolution

Aliases resolved before scope matching — `@nv` in item text stored as `@nvim` in frontmatter.
Aliases defined in `config.yaml` only; no global alias config.

### scope_map behavior

At add-time: cwd compared against scope_map keys (prefix match, relative to repo root).
All matching entries fire — scopes are additive.
Example: cwd = `dotfiles/nvim/plugin/` → `@nvim` + `@plugin` both added.

At list-time: same prefix match used to determine Active Scope set for here view.

## Version control

`.later-tasks/` may be committed (shared deferred work) or gitignored (personal scratchpad).
No opinion enforced by tool.
Committed items merge cleanly via git — each item is independent file, conflicts rare.
