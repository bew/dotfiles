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

Write long files as skeleton first (headers/signatures only), confirm structure, then fill each part with separate Edit call — never in one Write.

## Steps

1. **Assess** — Apply when: file has identifiable structural units (sections, functions, config blocks) AND is new or full rewrite.
   Skip only for trivially small files (single section, <15 lines) — normal Write is cleaner there.

2. **Confirm with user** — If not already agreed: ask *"Structured file — use incremental write (skeleton first, then fill each part)?"* If no, proceed with normal Write.

3. **Write skeleton** — Write structure only, no content bodies. Use Write tool.
   - Prose/spec: section headings + one-line placeholder (e.g. `<!-- TODO -->`)
   - Code: function/method signatures + `-- TODO` body stubs
   - Config: top-level keys + empty/minimal placeholder values

4. **Confirm structure** — If structure wasn't pre-agreed: ask *"Structure looks right? Proceed to fill sections?"* Edit skeleton if changes requested (Edit tool), re-confirm. Do not start filling until confirmed.

5. **Fill incrementally** — For each unit in order: replace placeholder via Edit tool. Complete one unit before moving to next. Don't batch multiple units into one Edit unless each is trivially small (1–2 lines). On Edit failure (placeholder mismatch): re-read file, locate current state, resume.

## Rules

- Never write full file in one Write call after incremental write was chosen.
- Always use Edit (not Write) for every fill step after initial skeleton.
- Never skip structure confirmation unless structure was already agreed upon with user.
- Ask once per task — don't re-ask for each file when writing multiple files.
- Don't use incremental write for files without structural units, or trivially small files (<15 lines); normal Write is cleaner.

## Guidelines

- Prefer filling top-to-bottom unless different order is more natural (e.g. helpers before callers).
- Trivially short adjacent sections (1–2 lines each) may be filled together in one Edit.
- Fill code stubs with full implementation, not another placeholder.
