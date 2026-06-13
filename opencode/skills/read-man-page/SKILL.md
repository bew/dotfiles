---
name: man-reader
description: |
  Token-efficient man page reading.
  Load when looking up CLI tool docs, flags, options, usage examples, config formats..
---

# Man Page Reader

## Goal

Read man pages in targeted chunks via `manq` (man query) script.
Never load full page.

## Choose `--help` vs `man`

| Situation | Action |
|---|---|
| Quick flag syntax, well-known tool | `<cmd> --help` |
| Tool has no man page | `<cmd> --help` |
| Man page not found by `manq` | `<cmd> --help`; or `man -k <cmd>` to find correct name |
| Full option semantics, exit codes, edge cases | `man` via this skill |
| EXAMPLES, FILES, ENVIRONMENT sections | `man` via this skill |
| `--help` terse or missing detail | `man` via this skill |

## Searching man pages (no script needed)

```sh
man -k <keyword>    # search by name/description (apropos)
man -K <string>     # full-text search across all man pages
```

## Man page sections

`manq` accepts `<name>` or `<name:N>` where `N` is section number:

| N | Topic |
|---|---|
| 1 | User commands |
| 2 | System calls |
| 3 | Library functions |
| 4 | Device files |
| 5 | File formats & config |
| 6 | Games |
| 7 | Misc (protocols, conventions) |
| 8 | Admin commands |

Omit `:N` to use first match.
Use `<name:N>` to disambiguate (e.g. `printf:1` vs `printf:3`, `githooks:5`).

## Script usage

Resolve `./scripts/manq` to absolute path before invoking.

```sh
<skill-dir>/scripts/manq <subcommand> <name[:N]> [options]
```

### Subcommands

**`toc`** — section list with line count, subsection count, condensed synopsis.
```sh
./scripts/manq toc grep
./scripts/manq toc grep -S OPTIONS        # TOC scoped to one section
./scripts/manq toc grep -L 2              # limit depth (default: all)
./scripts/manq toc grep -O                # include condensed options list
```

Common section names usable directly with `section` without running `toc` first:
`SYNOPSIS`, `DESCRIPTION`, `OPTIONS`, `FLAGS`, `EXAMPLES`, `FILES`, `ENVIRONMENT`, `EXIT STATUS`, `SEE ALSO`

**`section`** — extract one or more sections.
Use `--lines` to read incrementally.
`--lines` ranges are rendered-output line numbers (as printed), not source offsets.
```sh
./scripts/manq section grep EXAMPLES
./scripts/manq section grep OPTIONS EXAMPLES   # multiple in one call
./scripts/manq section grep OPTIONS --lines 1-50
./scripts/manq section grep OPTIONS --lines 51-100
```

**`flag`** — show description block for specific flags.
```sh
./scripts/manq flag grep -v
./scripts/manq flag grep -v --include      # multiple flags in one call
```

## Steps

1. Orient with `toc` if section names unknown. Use `-O` to include options summary.
2. Read known sections directly with `section`. Multiple sections in one call.
3. For long sections (>80 lines), read in 50-line increments with `--lines`.
4. Look up specific flags with `flag` instead of reading all of OPTIONS.

## Rules

- Never run bare `man <cmd>` — outputs full page.

## Guidelines

- `toc` synopsis may be truncated for complex tools (`ip`, `ffmpeg`) — use `section SYNOPSIS` for full form.
- `-O` output heuristic for non-standard man pages; cross-check with `section OPTIONS` if incomplete.
- `flag` matching exact (short + long form tried automatically); fuzzy matching not supported.
