---
name: read-nvim-help
description: |
  Token-efficient Neovim/Vim help reading.
  Load when looking up `:help` topics, nvim options, keymaps, Ex commands, Lua API (`vim.*`),
  or plugin docs (nvim-cmp, oil, lazy.nvim, which-key, …), or when asked anything answered by
  nvim runtime docs.
  Do NOT read `$VIMRUNTIME/doc/*.txt` raw, and do NOT open interactive `:help`, without loading
  this skill first.
metadata:
  maintainers: [bew]
---

# Nvim Help Reader

GOAL: Read Neovim help pages in targeted chunks via `nvimq` (nvim query) script.

## Help sources

| Source | Resolved from | Examples |
|---|---|---|
| Core | `$VIMRUNTIME/doc` | `help.txt`, `options.txt`, `lua-guide.txt`, `api.txt` |
| Plugins | runtimepath `doc/` dirs (with a `tags` file) | `nvim-cmp.txt`, `oil.txt`, `lazy.txt` |

Tags are the primary index: a tag maps to a file + line.
In help text a definition is `*tag*`, a reference is `|tag|`, and an option is `'opt'`.
`nvimq` accepts any of these forms as input and strips the markers.
Sections are the secondary structure: `=`-ruled (level 1) and `-`-ruled (level 2).

## Script usage

Resolve `./scripts/nvimq` to absolute path before invoking.

```sh
<skill-dir>/scripts/nvimq <subcommand> [options]
```

The Python front-end owns indexing, selection and markdown rendering.
It drives one `nvim --headless` instance (via `nvim -l`) over a JSON-lines pipe;
that backend only resolves runtime doc paths and parses help files with nvim's bundled
`vimdoc` treesitter parser, returning raw facts.
Requires `python3` and a loadable nvim config (plugin docs included).

### Subcommands

**`tag`** — resolve a tag to its definition, print a bounded block around it.
```sh
./scripts/nvimq tag lsp
./scripts/nvimq tag vim.lsp.start      # trailing () optional
./scripts/nvimq tag '|lsp|'            # |...| and *...* markers accepted
./scripts/nvimq tag number             # option names: bare or 'quoted'
./scripts/nvimq tag lsp -S plugin      # force a scope on collision
```
Matching is case-insensitive.
A trailing `()` is optional: `vim.lsp.start` resolves `vim.lsp.start()`.
Input accepts `lsp`, `|lsp|`, `*lsp*`, and option names (`number` or `'number'`).
To pass literal single quotes, use double quotes (`tag "'number'"`); a bare `number` also
resolves via the bare→quoted fallback.
If several tags match within the chosen scope, a warning lists each `stem.txt (scope)` on stderr
and the first runtimepath match is printed.
The block is markdown-rendered (see Output format).

**`toc`** — list a help file's sections (title + line count).
Prints the file name (`lsp.txt`) first, then one line per section.
```sh
./scripts/nvimq toc lsp
./scripts/nvimq toc options -S core      # core docs only
./scripts/nvimq toc lsp -L 2             # limit depth (default: all)
```

**`section`** — print one or more sections of a help file.
`--lines` ranges are rendered-output line numbers (as printed), not source offsets.
```sh
./scripts/nvimq section lsp QUICKSTART
./scripts/nvimq section lsp:QUICKSTART             # FILE:NAME form
./scripts/nvimq section lsp QUICKSTART DEFAULTS    # multiple sections
./scripts/nvimq section lsp 1                      # by toc ordinal
./scripts/nvimq section lsp QUICKSTART --lines 1-60
```
Section names are case-insensitive and matched by title, tag, or title substring.
`*...*` and `|...|` markers are stripped.
A bare number selects the 1-based ordinal in `toc` order (all heading levels).

**`find`** — search tags and section titles across all help files.
The pattern is matched as regex, glob, or substring (any hit wins).
`*...*` and `|...|` markers are stripped.
```sh
./scripts/nvimq find lsp
./scripts/nvimq find 'vim.lsp.*'
```
Each hit prints `stem.txt:line: name`.

### Options

| Flag | Applies to | Meaning |
|---|---|---|
| `-S <scope>` | `tag`, `toc`, `section`, `find` | `core`, `plugin`, or `all` (default `all`) |
| `-L <n>` | `toc` | Max section depth (default: all) |
| `--lines A-B` | `section`, `tag` | Print only printed-output lines A–B (not source offsets) |

Help file names accept a bare stem (`lsp`) or `stem.txt`; output always prints `stem.txt`.

## Output format

`section` and `tag` render help text as markdown-ish output:

- `=`-ruled titles become `## Title`; `-`-ruled titles become `### Title`; tag-headings and
  `~` column headings become `#### Title`; anchors are kept.
- Ruler lines (`====`, `----`) and `~` delimiters are dropped.
- Code blocks (`>lua`, `>vim`, or bare `>`) become fenced `lua`, `vim`, or plain blocks.
  A block ends at `<` or at the next unindented line.
  Code lines are de-indented by the common indent.
- Inline `*tag*` and `|ref|` anchors in the body are kept.

`toc` and `find` print help file names as `stem.txt`.

## Steps

1. **Locate** — use `tag` for a known tag, or `find` for a keyword/regex.
2. **Outline** — use `toc` when section names are unknown.
3. **Read** — print sections with `section`; multiple sections per call allowed.
4. **Chunk** — read long sections (>80 lines) in 60-line increments with `--lines`.

## Rules

- Never read `$VIMRUNTIME/doc/*.txt` or plugin `doc/*.txt` files directly — full files are huge.
- Never open interactive `:help`; it bypasses token control.
- Never spawn bare `nvim` to look something up — `nvimq` already resolves all doc paths.

## Guidelines

- Prefer `tag` over `find` when the exact tag is known — `tag` is exact and fast.
- A tag's block may spill into following lines; `tag` prints a bounded window.
  Widen with `--lines` if cut.
- If `tag` returns a core definition when you expected a plugin's, retry with `-S plugin`.
- `find` prints `stem.txt:line: name` (tags and section titles); no matches exits 0 empty.
- Plugin help only resolves if the plugin is installed in the active nvim config.