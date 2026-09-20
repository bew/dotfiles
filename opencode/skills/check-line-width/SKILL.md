---
name: check-line-width
description: |
  Load when checking line length, text width, prose, or column overflow — never use awk/grep/sed.
  Supports reading text from files or arbitrary text via stdin.
metadata:
  maintainers: [bew]
---

## Goal

Flag lines that exceed a given character width, in files or piped text.

## Usage

```
<skill-dir>/scripts/check-line-width <limit> [- | <files>...]
```
- `<limit>`: maximum allowed line width, in characters (positive integer)
- `<files>...`: one or more file paths (absolute or relative to cwd)
- `-`: read lines from stdin instead of a file; combinable with files, at most once

Examples:
- Check files: `<skill-dir>/scripts/check-line-width 100 src/foo.ts src/bar.ts`
- Check a command output: `command | <skill-dir>/scripts/check-line-width 100 -`
- Check multiline text via a quoted heredoc:
  ```sh
  <skill-dir>/scripts/check-line-width 72 - <<'EOF'
  This is an example commit message body with very long lines that must be checked!
  and more lines of text.

  And even more lines... The first line should be flagged here!
  EOF
  ```

When script outputs: `42: ome tex┃t is very long`
Meaning: On line 42, `t is very long` is beyond wanted limit.

## Rules

- Never use `awk`, `grep`, or ad-hoc shell pipelines to check line width.
  Always use the script instead.
- Feed multiline text via a quoted heredoc (`<<'EOF'`) with `-` as the file argument,
  not an `echo`/`printf` pipeline.
- Resolve `<skill-dir>` to the skill's absolute install path before invoking the script.
