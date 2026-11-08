---
name: check-semantic-breaks
description: |
  Load when checking wrapped semantic line breaks or semantic line breaks — never use awk/grep/sed
  or an ad-hoc shell check.
  Flags lines that pack more than one sentence, unless the extra sentence is small and the line fits
  within the width limit, in files or arbitrary text via stdin.
metadata:
  maintainers: [bew]
---

## Goal

Flag lines that pack more than one sentence, in files or piped text, unless the extra sentence is
small and the line it shares stays within the width limit.

## Usage

```
<skill-dir>/scripts/check-semantic-breaks [- | <files>...]
```
- `<files>...`: one or more file paths (absolute or relative to cwd)
- `-`: read lines from stdin instead of a file; combinable with files, at most once

A boundary is left alone only when both hold: the whole line fits within 100 columns, and the
sentence after the boundary holds 5 words or fewer.
Every other boundary is reported, so an over-wide line is flagged even when its trailing sentence is
a single word, and a line that fits is flagged when its second sentence runs long.
The width is fixed; there is no argument for it.

Exit status:
- `0`: every source was clean
- `1`: at least one hit was found
- `2`: usage error or unreadable file

Examples:
- Check files: `<skill-dir>/scripts/check-semantic-breaks README.md docs/foo.md`
- Check a commit body through a quoted heredoc:
  ```sh
  <skill-dir>/scripts/check-semantic-breaks - <<'EOF'
  Tighten the ship gate.
  It refuses to run unless the tree is clean. This contract changes how we release.
  EOF
  ```

When script outputs: `2: …… tree is clean. ┃This contract changes ……`
Meaning: on line 2, a second sentence begins at `┃`, and the line cannot afford it.
A hit keeps a window of words around its boundaries — three words for a lone boundary, two when the
line carries several — marks each boundary inside that window, and stands `……` in for the rest.
Scanning this file reports the example above as a real hit.

## What counts as a boundary

A period, exclamation mark, or question mark ends a sentence only when whitespace follows it and a
non-whitespace character comes next.
Tokens built from dots therefore never end a sentence on their own: `1.2`, `SKILL.md`,
`example.com`, `e.g`.
Two more forms are skipped, so a hit stays trustworthy: an ordered-list marker (`1. Foo`) and a
trailer abbreviation (`etc`, `vs`, `cf`, `al`, `fig`, `no`, `approx`, `resp`, `viz`, `e.g`, `i.e`).

## Rules

- Never use `awk`, `grep`, or ad-hoc shell pipelines to check for packed sentences.
  Always use the script instead.
- Feed multiline text via a quoted heredoc (`<<'EOF'`) with `-` as the file argument,
  not an `echo`/`printf` pipeline.
- Resolve `<skill-dir>` to the skill's absolute install path before invoking the script.
- The script only reports; fix a flagged line by hand, applying wrapped semantic line breaks.
