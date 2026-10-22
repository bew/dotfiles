# CLI API

`later` binary: standalone Nushell script (`#!/usr/bin/env nu`).
Follows `bin/` conventions: all logic in named functions, `main` at bottom, `usage_and_exit` for errors.

## Invocation model

```
later <kind-subcmd> --when <level> <text>
later add --when <level> --kind <kind> <text>
later ls [<view>] [--when <level>]
later status
```

Kind subcommands are primary add path.
`add` is fallback for free-form kinds not in predefined table.
Use `@global` (alias `@glob`) anywhere in `<text>` to route item to Global Storage Dir.

## Subcommands

### Kind subcommands (add an item)

Each predefined Kind: subcommand + one or more short aliases.
`--when` always required — no default.

| Subcommand | Aliases | Kind stored |
|---|---|---|
| `todo` | `t`, `td` | `todo` |
| `fix` | `fx`, `f` | `fix` |
| `try` | `tr` | `try` |
| `spec` | `sp` | `spec` |
| `idea` | `i` | `idea` |
| `add` | `a` | _(requires `--kind <value>`)_ |

`add` (alias `a`): escape hatch for free-form kinds not in table.
All kind subcommands accept same flags.

#### Examples

```sh
later fix --when next "broken symlink in nvim spell dir @nvim"
later fx -w n "broken symlink in nvim spell dir @nvim"   # same, short aliases
later try --when soon "nu table output for ls"
later idea --when maybe "integrate later with obsidian"
later add --when someday --kind research "look into nix flake outputs spec"
```

### `ls` — list items

#### Variants

| Invocation | View | What is shown |
|---|---|---|
| `later ls` | here | Active Scope items grouped by level (next→maybe); summary line per other scope |
| `later ls repo` (alias `r`) | repo | All items in Local Storage Dir + Global items matching repo scope |
| `later ls all` (alias `a`) | all | All items across all Storage Dirs, grouped by scope then level |

`--when <level>` filters any variant to single level.

#### here view output format

Plain text, one line per item:

```
[next]  (fix)  fix broken symlink in nvim spell dir
[next]  (try)  try nu table output for ls

  @work  →  3 next, 1 soon
  @rust  →  1 maybe
```

- Active Scope items listed first, grouped by level in proximity order (`next` → `maybe`).
- Blank line separates item list from scope summary block.
- Each summary line: scope name + count per level (non-zero only).
- `@scope` column omitted from item lines in here view — all items share same scope.

#### repo / all view output format

```
@dotfiles
  [next]  (fix)  fix broken symlink in nvim spell dir
  [next]  (try)  try nu table output for ls
  [soon]  (spec) spec the later scope system

@dotfiles @nvim
  [next]  (fix)  check nvim spell parent dir creation

@work
  [soon]  (todo) review PR #42
```

Items grouped by Scope set, then by level within each group.

### `status` — summary overview

`later status` (alias `st`): compact overview across all Storage Dirs, grouped by level, counts per scope.
Quick "what's queued" glance without listing individual items.

```
later status

  next:     4  (@dotfiles ×2, @nvim ×1, @work ×1)
  soon:     2  (@dotfiles ×1, @work ×1)
  someday:  1  (@dotfiles ×1)
  maybe:    3  (global ×2, @rust ×1)
```

## Scope system

### Auto-detection at add-time

`later` derives Active Scope automatically:

1. `git remote get-url origin` (or first available remote).
   Extract repo basename (strip host, org, `.git` suffix).
   Example: `git@github.com:bew/dotfiles.git` → `@dotfiles`.
2. No git remote → `basename (git rev-parse --show-toplevel)`.
3. Not in git repo + no `.later-tasks/` at cwd → scope = `@global`, route to Global Storage Dir.

**scope_map enrichment** (if `config.yaml` present in Local Storage Dir):
After step 1/2, cwd is compared against `scope_map` keys (prefix match, relative to repo root).
All matching entries fire — scopes are additive.
Example: cwd = `dotfiles/nvim/plugin/` with scope_map `nvim/ → @nvim`, `nvim/plugin/ → @plugin`
→ Active Scope = `[@dotfiles, @nvim, @plugin]`.

**Alias resolution**: `@word` tokens (inline or `--scope`) resolved through `scope_aliases` before storage.
Canonical form always stored in frontmatter.

Auto-detected scopes + scope_map scopes + inline `@word` tokens all merged into item `scopes` field.
If item text already contains `@global` / `@glob`, forces Global Storage Dir routing regardless of git context.

### Inline @-tokens

Any `@word` in item text extracted as additional Scope.
Token kept in body text as-is (not stripped).
Allows natural phrasing: `"fix broken symlink @nvim @plugin"`.

### Active Scope at list-time

`later ls` (here view) uses same detection logic as add-time.
Item shown if `scopes` field contains Active Scope.
Items with no matching scope appear only in summary block, not item list.

## Flags reference

| Flag | Short | Applies to | Description |
|---|---|---|---|
| `--when <level>` | `-w` | kind subcmds, `add` | Required for add; optional filter for `ls` |
| `--kind <value>` | `-k` | `add` only | Kind value for generic `add` subcommand |
| `--scope <@word>` | `-s` | kind subcmds, `add` | Explicit additional scope (may repeat); additive to auto-detection |

NOTE: `--scope` is additive — does not replace auto-detected scopes.
`@global` / `@glob` in text routes to Global Storage Dir + stored as `@global` scope (canonical form).
To suppress auto-detection, use `--no-auto-scope` (open question — see [SPEC.md](SPEC.md#open-questions)).
