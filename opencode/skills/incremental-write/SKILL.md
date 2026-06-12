---
name: incremental-write
description: |
  Pattern for writing long files incrementally: skeleton first, then fill each section/function
  via targeted edits. Improves reviewability and avoids large opaque writes.
  Load when considering whether to incrementally write a long structured file (spec, code, config, etc.).
---

## Goal

Write long files as skeleton first (headers/signatures only), confirm structure, then fill each part with a separate Edit call — never in one Write.

## Steps

1. **Assess** — Apply when: file has identifiable structural units (sections, functions, config blocks) AND is non-trivial to review in one write (>40–50 lines or >3 sections) AND is new or a full rewrite.

2. **Confirm with user** — If not already agreed: ask *"Long structured file — use incremental write (skeleton first, then fill each part)?"* If no, proceed with normal Write.

3. **Write skeleton** — Write structure only, no content bodies. Use the Write tool.
   - Prose/spec: section headings + one-line placeholder (e.g. `<!-- TODO -->`)
   - Code: function/method signatures + `-- TODO` body stubs
   - Config: top-level keys + empty/minimal placeholder values

4. **Confirm structure** — If structure wasn't pre-agreed: ask *"Structure looks right? Proceed to fill sections?"* Edit skeleton if changes requested (Edit tool), re-confirm. Do not start filling until confirmed.

5. **Fill incrementally** — For each unit in order: replace placeholder via Edit tool. Complete one unit before moving to the next. Don't batch multiple units into one Edit unless each is trivially small (1–2 lines). On Edit failure (placeholder mismatch): re-read the file, locate current state, resume.

## Rules

- Never write a full file in one Write call after incremental write was chosen.
- Always use Edit (not Write) for every fill step after the initial skeleton.
- Never skip structure confirmation unless the structure was already agreed upon with the user.
- Ask once per task — don't re-ask for each file when writing multiple files.
- Don't use incremental write for short files or files without structural units; normal Write is cleaner.

## Guidelines

- Prefer filling top-to-bottom unless a different order is more natural (e.g. helpers before callers).
- Trivially short adjacent sections (1–2 lines each) may be filled together in one Edit.
- Fill code stubs with full implementation, not another placeholder.
