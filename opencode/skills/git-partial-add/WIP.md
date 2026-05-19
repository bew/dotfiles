# WIP — git-partial-add skill

Things not yet implemented or not yet tested. Pick up from here.

---

## patch_hunk.py — missing / untested

### `override staged` modifier (stub)

`rewrite_override_staged` in `patch_hunk.py` is a rough stub. The intent:

> Fix what's already in the index — e.g. un-stage a line that was staged too eagerly,
> or replace a staged line with a corrected version.

The caller would pass `git diff --cached -- <file>` as the diff input instead of
`git diff -- <file>`. The script logic should be identical to `override staging` —
the distinction is entirely in which diff is fed as input. The stub currently discards
all original change lines and rebuilds the body from context + override lines, which
is wrong for the general case.

**To fix:** `rewrite_override_staged` should behave like `rewrite_override_staging`
(same logic). The `staged` vs `staging` distinction is a caller-side concern (which
diff to pass), not a script-side concern. Consider merging the two into one function
and documenting that the caller controls the diff source.

### `new_start` drift in multi-hunk rewrites

When multiple hunks in the same file are rewritten with different net line-count deltas
(e.g. hunk 1 adds 1 line, hunk 2 drops 2 lines), the `new_start` offsets of subsequent
hunks become stale — they are inherited verbatim from the original diff.

`git apply` is tolerant of this in practice (it uses fuzzy matching), but it can fail
on tight diffs. A correct implementation would accumulate a running `delta` (net lines
added/removed so far) and adjust `new_start` for each subsequent hunk.

**To fix:** in `main()`, after computing each rewritten hunk, track cumulative delta and
adjust `hunk.new_start` before appending.

### No-op partial hunk — silent drop vs. explicit report

When a `partial` action excludes all change lines, the hunk is silently dropped (no
output, no stderr note). This is correct for `git apply` but may confuse the caller
(no feedback that the hunk was intentionally a no-op).

**To fix:** emit a stderr note: `# noop file.py hunk N: all change lines excluded`

### `--intent-to-add` detection for new files

When the diff contains a new-file hunk (`--- /dev/null`), the script does not warn the
caller that `git add --intent-to-add <file>` must be run first. Without it, `git apply
--cached` will fail with "does not match index".

**To fix:** detect `--- /dev/null` in `FileDiff.file_type == "new"` and emit a stderr
warning: `# warning: new file <path> — run: git add --intent-to-add <path>`

### Unit tests

The examples block at the bottom of `patch_hunk.py` documents 4 test cases against the
fixture diff at `/tmp/opencode/test.diff`. These should be turned into proper pytest
tests. The fixture setup (committed file + modified working tree) needs to be a reusable
fixture function.

Cases still missing from the examples:
- `partial` excluding a `-` line (demote removal to context)
- `override staged` (once the stub is fixed)
- Binary file skip
- New file with `--intent-to-add`
- Deleted file stage
- Multi-hunk rewrite with `new_start` delta correction

---

## Skill — easy mode gaps

### Partial hunk with `-` line exclusion

Easy mode documents demoting `-` lines to context but this path is not tested end-to-end.
The `rewrite_partial` function in `patch_hunk.py` handles it correctly — easy mode should
mirror the same logic.

### `staged` modifier in easy mode

Easy mode has no equivalent of `override staged`. If the user wants to fix the index
(un-stage a specific line), they must use granular mode. This is not documented explicitly
in the skill — add a note.

---

## Skill — description trigger

The skill description says "Load when the user asks to stage only some changes…".
Consider whether it should also trigger on:
- "undo part of what I staged"
- "fix my staged changes"
- "I staged too much"

These map to the `staged` modifier use case and are not currently called out.
