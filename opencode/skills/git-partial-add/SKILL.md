---
name: git-partial-add
description: |
  Stage specific hunks or partial hunks from the current diff without interactive input.
  Load when the user asks to stage only some changes, specific hunks, or parts of hunks —
  e.g. "stage only the auth changes", "add just this part", "don't stage the debug lines".
  Supports easy mode (direct patch construction) and granular mode (via patch_hunk.py script
  for sub-line content overrides and complex rewrites).
---

## Goal

Produce a valid staged index state that includes exactly the hunks (or partial hunks) matching
the user's intent, leaving all other changes unstaged.

## Mode selection

Use **easy mode** when:
- Staging or skipping whole hunks
- Excluding a small number of lines from a hunk (demote to context)
- No sub-line content editing needed

Use **granular mode** when:
- Staging a modified version of a line (neither old nor new working-tree content)
- Fixing an already-staged hunk (`staged` modifier)
- Complex partial rewrites with many interleaved exclusions

---

## Steps

### 1. Obtain the diff

- Check recent conversation context for a `git diff` output already visible. Use it directly —
  do not re-run `git diff`.
- If not in context and scope is clear (user named files), run `git diff -- <paths>`.
- If scope is ambiguous, ask: "Which files or changes should I look at?"

### 2. Parse hunks

Split the diff into individual hunks delimited by `@@ ... @@` headers. Group by file.
For each file, note its type:
- **New file** — diff header contains `--- /dev/null`
- **Deleted file** — diff header contains `+++ /dev/null`
- **Binary file** — diff body contains `Binary files … differ`
- **Modified file** — all other cases

Label each hunk with its file path and a one-line description of its content.

### 3. Classify hunks against intent

For each hunk decide:
- **Stage as-is** — fully matches intent
- **Stage partially** — partially matches; some lines to exclude
- **Stage with override** — content to stage differs from working-tree version (granular mode only)
- **Skip** — does not match intent

Use the user's explicit instruction first; fall back to inferred task context.
When ambiguous, skip and explain.

### 4. Apply

Follow the mode-specific steps below.

---

## Easy mode

Construct and apply patch fragments directly without the script.

### Full hunk

Extract verbatim from the diff. Each fragment must include the file header:

```
diff --git a/<path> b/<path>
--- a/<path>
+++ b/<path>
@@ ... @@
<hunk body>
```

### Partial hunk

Rewrite the hunk body by demoting unwanted change lines back to context:

| Line type | Action to exclude |
|-----------|------------------|
| `-`/`+` pair | remove both; insert original as context (`' '`) |
| lone `+` | remove entirely |
| lone `-` | remove; keep original line as context |

Recompute `@@ -a,b +c,d @@` header:
- `b` = context lines + remaining `-` lines
- `d` = context lines + remaining `+` lines

NOTE: If partial rewriting is too complex to do correctly inline (many interleaved
exclusions), do NOT fall back to staging as-is. Skip the hunk, explain why, and tell the
user to stage it manually or use granular mode.

### Apply each fragment

```sh
git apply --cached <<'EOF'
<patch fragment>
EOF
```

Apply one fragment at a time. Stop and report the raw error if any fragment fails.

### Special file types

**New file:** run `git add --intent-to-add <file>` before applying the patch.

**Deleted file:** only full-file deletion is supported. Stage verbatim or skip.

**Binary file:** skip always. Tell the user to run `git add <file>` manually.

---

## Granular mode

Uses `./scripts/patch_hunk.py`. Read `./references/patch_hunk_spec.md` for the full spec.

### 1. Save the diff to a temp file

```sh
# if diff not already on disk:
git diff -- <paths> > /tmp/patch_hunk_input.diff
```

### 2. Write instructions

Build an instruction string (tab-separated fields). See spec for full format.

```
# stage hunk 1 as-is
foo.py\t1\tstage
# skip hunk 2
foo.py\t2\tskip
# stage hunk 3 but replace the added line content
foo.py\t3\toverride\tstaging
+    foo(x, verbose=True)
---
```

### 3. Run the script and apply

```sh
python3 ~/.config/opencode/skills/git-partial-add/scripts/patch_hunk.py \
  /tmp/patch_hunk_input.diff <<'EOF' > /tmp/patch_hunk_output.patch
<instructions>
EOF

# Guard: only apply if output is non-empty
[ -s /tmp/patch_hunk_output.patch ] && git apply --cached /tmp/patch_hunk_output.patch
```

Script writes skipped-hunk notes to stderr. Stop and report if `git apply` fails.

---

## Verification

After all applies complete, run **one batched** verification over all affected files:

```sh
git diff --cached -- <file1> <file2> ...
```

Never run `git diff --cached` without a file path filter.
Never verify per-hunk or per-apply — batch over all affected files at the end.

---

## Report

List results grouped by file:

```
Staged:
  file.py  @@ -1,5 +1,6 @@    added z=3 to foo()
  file.py  @@ -7,5 +8,6 @@    (partial) added c=30 to bar(), excluded d line
  new.py   @@ -0,0 +1,10 @@   (new file) full file staged
  old.py                       (deleted file) staged for deletion

Skipped:
  file.py  @@ -13,5 +14,6 @@  baz() change — not related to auth feature
  file.py  @@ -20,8 +21,9 @@  (manual required) complex rewrite — stage manually
  img.png                      (binary) stage manually: git add img.png
```

---

## Rules

- Never run `git add -p` (requires tty).
- Never run plain `git add` or `git add -u` — only `git apply --cached`
  (and `git add --intent-to-add` for new files).
- Never attempt `git apply` on a binary diff.
- Never partially rewrite a deleted-file hunk — stage full deletion or skip.
- Never stage a hunk not matching the user's intent.
- Never run `git diff --cached` without a file path filter.
- Never fall back to staging as-is when a rewrite fails — skip and tell the user.
- Never omit the file header (`diff --git …`, `--- a/…`, `+++ b/…`) from a patch fragment.
- If diff is absent from context and scope is unclear, ask before running any git command.
- If `git apply --cached` fails, stop, show the raw error, do not continue.
- Run verification once, batched, after all applies complete.

## Guidelines

- Prefer reusing diff already in context over re-running `git diff`.
- Prefer easy mode unless sub-line editing is needed.
- When inferring intent from task context, prefer conservative matching (false negative over
  false positive).
- If a hunk is large and only one line needs excluding, mention the complexity tradeoff
  before attempting the rewrite.
