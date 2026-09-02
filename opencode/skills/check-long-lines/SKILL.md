---
name: check-long-lines
description: |
  Always load whenever checking, reporting, or verifying line length in any text — never use awk, grep, sed, or ad-hoc shell for this.
  Supports reading text from files or arbitrary text via stdin.
  Load when the task involves a line-length check, column overflow report, or prose-limit verification.
metadata:
  maintainers: [bew]
---

## Usage

```
<skill-dir>/scripts/check-long-lines <limit> [- | <files>...]
```
- `<limit>`: maximum allowed line length (positive integer)
- `<files>...`: one or more file paths (absolute or relative to cwd)
- `-`: read lines from stdin instead of a file; combinable with files, at most once

Examples:
- Check files: `<skill-dir>/scripts/check-long-lines 100 src/foo.ts src/bar.ts`
- Check a command output: `command | <skill-dir>/scripts/check-long-lines 100 -`
- Check arbitrary text:
  ```sh
  <skill-dir>/scripts/check-long-lines 72 <<'EOF'
  This is an example commit message body with very long lines that must be checked!
  and more lines of text.

  And even more lines... The first line should be flagged here!
  EOF
  ```

When script outputs: `42: ome tex┃t is very long`
Meaning: On line 42, `t is very long` is beyond wanted limit.

## Rules

- Never use `awk`, `grep`, or ad-hoc shell pipelines to check line lengths.
  Always use the script instead.
- Resolve `<skill-dir>` to the skill's absolute install path before invoking the script.
