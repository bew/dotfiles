---
name: check-long-lines
description: |
  Use when the agent needs to find or report lines exceeding a length limit in one or more files.
  (do NOT use `awk` or any other ad-hoc method)
  Load when about to check line lengths, report long lines, or compute column overflow in any file.
metadata:
  maintainers: [bew]
---

## Usage

```
<skill-dir>/scripts/check-long-lines <limit> <files>...
```
- `<limit>`: maximum allowed line length (positive integer)
- `<files>...`: one or more file paths (absolute or relative to cwd)

When script outputs: `42: ome tex┃t is very long`
Line 42: `t is very long` is beyond wanted limit.

## Rules

- Never use `awk`, `grep`, or ad-hoc shell pipelines to check line lengths.
  Always use the script instead.
- Resolve `<skill-dir>` to the skill's absolute install path before invoking the script.
