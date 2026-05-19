# patch_hunk.py — spec

## Purpose

Rewrite git unified diff hunks according to per-hunk instructions, producing a valid patch
suitable for `git apply --cached`. Supports full staging, skipping, partial hunk exclusion,
and sub-line content override.

---

## Invocation

```sh
patch_hunk.py <diff-file> < instructions.txt | git apply --cached
```

- `<diff-file>`: path to a unified diff (output of `git diff` or `git diff --cached`)
- `instructions.txt`: read from stdin, tab-separated, described below
- stdout: assembled patch ready for `git apply --cached`
- stderr: one line per skipped hunk — `# skipped <file> hunk <N>: <reason>`

---

## Instruction format

One instruction per line. Fields separated by **tab** characters (not spaces — filenames may
contain spaces).

```
<file>\t<hunk-index>\t<action>[\t<modifier>]
```

- `file`: path exactly as it appears in the diff (`b/` prefix stripped)
- `hunk-index`: 1-based position of the hunk within that file's diff
- `action`: one of `stage`, `skip`, `partial`, `override`
- `modifier`: action-specific (see below)

Lines starting with `#` are comments and ignored. Blank lines ignored.

**Default behavior**: any hunk not mentioned in instructions is staged as-is.

---

## Actions

### `stage`

Stage the hunk verbatim. No modifier.

```
foo.py\t1\tstage
```

### `skip`

Do not include this hunk in the output patch.

```
foo.py\t2\tskip
```

### `partial`

Stage the hunk but exclude specific body lines (1-based index within the hunk body,
not counting the `@@` header line itself).

Modifier: comma-separated 1-based line numbers to exclude.

```
foo.py\t3\tpartial\t4,7
```

Exclusion semantics per line type:
- `+` line excluded → dropped entirely (not staged)
- `-` line excluded → demoted to context (kept as-is in both old and new)
- context line excluded → kept as context (no-op)

Header `@@ -a,b +c,d @@` is recomputed after exclusions:
- `b` (old count) = context lines + remaining `-` lines
- `d` (new count) = context lines + remaining `+` lines

If the result would be a no-op patch (no `+` or `-` lines remain), the hunk is silently
dropped — `git apply` rejects pure-context patches.

NOTE: If all hunks are dropped or skipped, stdout is empty. The caller must guard against
piping empty output to `git apply` (use `--allow-empty` or check stdout before piping).

### `override`

Replace or adjust specific change lines in the hunk. Used when the desired staged content
differs from both the old and new working-tree versions.

Modifier: `staging` or `staged`

Followed by an override block terminated by `---` on its own line:

```
foo.py\t4\toverride\tstaging
+    foo(x, verbose=True)
---
```

Override block lines:
- `+<content>`: a line to add (replaces the next `+` line in the hunk in order)
- `-<content>`: a `-` line to demote to context (keep old content, don't remove it)

#### `staging` modifier

Modifies **what gets staged** (the `+` side of the patch):

- `+` override lines replace original `+` lines in the hunk, one-to-one in order
- If fewer `+` overrides than original `+` lines, remaining `+` lines are dropped
- `-` override lines cause matching `-` lines to be treated as context (not removed)

Use case: stage a different version of a line than what's in the working tree.

```
# diff has: -foo(x)  +foo(x, debug=True, verbose=True)
# we want to stage only: +foo(x, verbose=True)
foo.py\t2\toverride\tstaging
+    foo(x, verbose=True)
---
```

#### `staged` modifier

Modifies **what the index looks like after** — used to fix an already-staged hunk
(e.g. a previous too-eager `git add`). Operates on `git diff --cached` output.

All context lines from the original hunk are preserved. The override block's `+`/`-`
lines replace the hunk's change lines entirely.

- `+<content>`: add this line to the index
- `-<content>`: remove this line from the index

Use case: un-stage a specific line that was staged too eagerly, or correct a staged line.

---

## New and deleted files

**New file** (`--- /dev/null` in diff header):
- Caller must run `git add --intent-to-add <file>` before piping to `git apply --cached`
- The script does not run this automatically; it will be noted on stderr if detected
  (detection: TBD, currently not implemented)

**Deleted file** (`+++ /dev/null` in diff header):
- Only `stage` or `skip` are valid actions; partial/override are rejected
- Full deletion patch is emitted verbatim

**Binary file** (`Binary files ... differ` in diff body):
- Always skipped with reason on stderr; no patch fragment emitted

---

## Error handling

- Unknown action → skipped, reason on stderr
- `partial` missing modifier → skipped
- `override` missing block or unknown modifier → skipped
- Hunk index out of range → skipped
- Partial/override rewrite producing invalid state → skipped (not emitted), reason on stderr

**Never falls back to staging as-is on rewrite failure.**

---

## Test fixtures

Located in `/tmp/opencode/` (ephemeral, recreated per test run).

### Fixture: `test.diff`

Three-hunk diff of `file.py`. Each hunk adds one line to a different function,
separated by enough context lines (≥7) that git creates separate hunks.

Structure of old file (committed):
```
def foo():          # line 1
    x = 1           # line 2
    return x        # line 3
# padding 0-19      # lines 4-23
def bar():          # line 24
    a = 10          # line 25
    return a        # line 26
# padding2 0-19     # lines 27-46
def baz():          # line 47
    p = 100         # line 48
    return p        # line 49
```

New file adds:
- `z = 3` after `x = 1` in `foo` → hunk 1
- `c = 30` after `a = 10` in `bar` → hunk 2
- `q = 200` after `p = 100` in `baz` → hunk 3

### Tested scenarios

| Test | Instructions | Expected staged result |
|------|-------------|------------------------|
| 1 | stage 1+3, skip 2 | `z=3` and `q=200` staged; `c=30` not staged |
| 2 | override staging on hunk 2: `+c=99` | `c=99` staged instead of `c=30` |
| 3 | no instructions (empty stdin) | all three lines staged |
| 4 | partial hunk 2, exclude the `+` body line | hunk 2 applied as pure context (no change staged) |

---

## Known issues / TODO

- `rewrite_override_staged` is a stub; `staged` modifier not fully tested
- No detection of new-file hunks for `--intent-to-add` warning
- `partial` with excluded `-` lines (demote removal to context) not yet tested
- `new_start` in rewritten hunks is not recalculated (inherited from original); this is
  correct for single-file sequential application but may drift if multiple hunks in same
  file are rewritten with different net line-count deltas
