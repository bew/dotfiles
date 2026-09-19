---
name: text-replace
description: |
  Always load when performing bulk/mechanical text search & replace over one or more files.
  Covers literal rewrites and bulk renames.
  Triggers when asked to "find and replace", "bulk rename", "rewrite all occurrences",
  "replace this token everywhere", or when about to run `sed -i`/`perl -pi`.
  Regex replacement is also supported.
metadata:
  maintainers: [bew]
---

# Text Replace

## Goal

Replace text in files or streams using `sd`.
Prefer `sd` over `sed -i`, `perl -pi`, or `awk` for edits.
Default to exact literal matches; reach for regex only when literal matching is insufficient.
Prefer whole-word matching when replacing a word, keyword, or identifier (see <§word-boundaries>).

Read <./refs/regex.md> before any replacement that is not a plain literal (`-F`) match.

## Exact replacement

```sh
sd -F 'OLD' 'NEW' FILE...          # literal substring
sd -F -f w 'OLD' 'NEW' FILE...     # literal whole word — for word, keyword, or identifier
```

- `-F` makes `OLD`/`NEW` literal — no metacharacters, no capture expansion.
- Files are modified **in place** by default — no backup written.
- Omit `FILE...` to read stdin and write stdout.
- Whole-word matching (`-f w`): see <§word-boundaries>.
- Separate a leading-dash pattern with `--`: `sd -F -- '-x-' 'Y' file.txt`.
- Single-quote patterns so the shell does not expand globs or `$`.

Prefer `-F` even when the text looks regex-safe — it documents intent and removes surprises.

## Word boundaries
<!-- §word-boundaries -->

Use whole-word matching by default when replacing a word, keyword, or identifier —
unless the edit is inside a word.
Add `-f w`:

```sh
sd -F -f w 'foo' 'bar' FILE...    # foo -> bar; foobar, my_foo untouched
```

Without `-f w`, `FIND` matches every substring occurrence.
`foo` also rewrites `foobar`, `food`, and `foo_bar` — the most common bulk-edit bug.

Drop `-f w` only when the edit is inside a word
(renaming a prefix, or a literal that is itself a fragment).

## Planning the rewrite

Cheapest correct strategy first.
Decide *what* to replace before running anything.

- Count the blast radius: `rg -c -F 'OLD' path/` (per file) or `rg -l -F 'OLD' path/` (files only).
- If **most** matches should change and only a few must stay: replace all, then revert the few.
  Reverting a handful is cheaper than hand-editing every correct match.
- If **most** matches must stay and only a few change: do not replace all — narrow the scope.
  Scope by file (`rg -l`) or by context (longer literal, `-f w`).
- Watch substring collisions: replacing `foo` also hits `foobar` and `foo_bar`.
  Use `-f w` or a longer literal when the token can appear inside others.
- Watch chained collisions: `a→b` followed by `b→c` turns original `a` into `c`.
  Order rewrites to avoid this, or route through a placeholder token
  (`a→@@TMP@@`, `b→c`, `@@TMP@@→b`).
- Keep a bulk rewrite as its own isolated change/commit so review and revert stay simple.

Reverting exceptions after a replace-all:

- Scoped second pass: `sd -F 'NEW' 'OLD'` on just the files that needed the old value.
- Manual edit for individual occurrences.
- Verify: targeted search still finds the old token only where expected (`rg -c -F 'OLD'`).

## Common flags

| Flag | Meaning |
|---|---|
| `-F, --fixed-strings` | Treat `FIND`/`REPLACE` as literals |
| `-f, --flags <FLAGS>` | Regex flags, combinable (e.g. `-f iw`); `w` = whole words |
| `-n, --max-replacements <N>` | Cap replacements per file (0 = unlimited) |
| `-A, --across` | Match across line boundaries |

## Workflow

1. **Plan** — scope the change with targeted searches (`rg -c -F 'OLD'`, `rg -l`).
2. **Apply** — run `sd`. Files change in place.
3. **Verify** — re-read the affected parts of the files, and recount old/new matches with `rg -c`.

## Batch file edits

`sd` takes explicit files — no recursive globbing.
Generate the file list, then pipe it:

```sh
rg -l -F 'OLD' path/ | xargs sd -F 'OLD' 'NEW'
fd -e md . docs/ | xargs sd -F 'old' 'new'
```

## Rules

- ALWAYS scope the change with targeted searches before replacing.
- NEVER run an unreviewed replace across many files or a whole repo.
- Use `-F` for literal text.
  Without it, regex metacharacters (`.`, `*`, `(`, `$`, `?`, `+`) change meaning.
- Use `-f w` by default for word, keyword, or identifier replacements (see <§word-boundaries>).
- Quote patterns in single quotes.
- After bulk edits, run the project's formatter/linter/tests if code was touched.

## Gotchas

- `sd` overwrites files with no backup — rely on VCS, not on `sd`, for recovery.
- `sd` exits `0` even when `FIND` matches nothing — a silent no-op.
  Confirm the rewrite landed with an `rg -c` recount.
- `-f w` only matches when `FIND` starts and ends with a word character.
  `sd -F -f w '-x-'` silently matches nothing.
- Without `-F`, `FIND` is a regex (see <./refs/regex.md>) — `.` matches any char, `$` is an anchor.
- Stdin mode writes to stdout only; it never edits files.
