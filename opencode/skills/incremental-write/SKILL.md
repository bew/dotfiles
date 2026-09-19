---
name: incremental-write
description: |
  Pattern for writing structured files incrementally: skeleton first, then fill each section/function
  via targeted edits. Improves reviewability and avoids large opaque writes.
  Load when writing or rewriting any structured file with identifiable sections:
  spec, design doc, README, config, code module, skill/agent/command artefact, etc.
  Applies regardless of file length — structure is the trigger, not line count.
---

## Goal

Write long files as skeleton first (headers/signatures + per-part TODO overview), confirm structure, then fill each part with separate Edit call — never in one Write.

## Steps

1. **Assess** — Apply when: file has identifiable structural units (sections, functions, config blocks) AND is new or full rewrite.
   Skip only for trivially small files (single section, <15 lines) — normal Write is cleaner there.

2. **Confirm with user** — If not already agreed: ask *"Structured file — use incremental write (skeleton first, then fill each part)?"* If no, proceed with normal Write.

3. **Write skeleton** — Write structure + per-part placeholder, no content bodies. Use Write tool.
   Each placeholder = a `TODO` comment containing a 1–2 line overview of the part's content.
   Scale to complexity: 1 line for trivial parts, 2 when content is non-obvious.
   - Prose/spec: heading + `<!-- TODO: <1–2 line overview> -->`
   - Code: function/method signature + `TODO: <1–2 line overview>` in the file's comment syntax
   - Config: top-level key + `# TODO: <1–2 line overview>` comment

4. **Confirm structure** — If structure wasn't pre-agreed: ask *"Structure looks right? Proceed to fill sections?"* Edit skeleton if changes requested (Edit tool), re-confirm. Do not start filling until confirmed.

5. **Fill incrementally** — For each unit in order: replace the placeholder comment (overview included) via Edit tool. Complete one unit before moving to next. Don't batch multiple units into one Edit unless each is trivially small (1–2 lines). On Edit failure (placeholder mismatch): re-read file, locate current state, resume.

## Rules

- Never write full file in one Write call after incremental write was chosen.
- Always use Edit (not Write) for every fill step after initial skeleton.
- Every skeleton placeholder has a `TODO` comment with a 1–2 line overview — never bare `TODO`.
- Never skip structure confirmation unless structure was already agreed upon with user.
- Ask once per task — don't re-ask for each file when writing multiple files.
- Don't use incremental write for files without structural units, or trivially small files (<15 lines); normal Write is cleaner.

## Guidelines

- Prefer filling top-to-bottom unless different order is more natural (e.g. helpers before callers).
- Trivially short adjacent sections (1–2 lines each) may be filled together in one Edit.
- Fill code stubs with full implementation, not another placeholder.
