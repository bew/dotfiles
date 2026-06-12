---
name: bew-inline-callout-style
description: |
  Convention for inline callout markers in prose and artefact files.
  Reference-only — not auto-loaded. Load explicitly when writing or reviewing
  documents that follow bew's personal notes style.
---

# Inline Callout Style

Callout markers draw attention to secondary info that should stand out in prose.
Use when careful reader might otherwise miss or skip the info.
No hard limit on count — if callouts appear frequently, prose likely needs rewriting rather
than more markers.

## Keywords

Common keywords and intended semantics:

- `NOTE:` — context or secondary info reader should not miss; doesn't block progress.
- `IMPORTANT:` — hard constraint. Must be followed to produce correct output.
- `WARNING:` — risk. Bad outcome if ignored.
- `TIP:` — actionable shortcut or best practice. Use rarely.
- `TRADEOFF:` — competing forces with no single right answer; surfaces the tension.

List above is not exhaustive. Use other UPPERCASE keywords when none fit, as
long as keyword clearly signals nature of callout (e.g. `CONTEXT:`, `CAVEAT:`,
`ASSUMPTION:`). Prefer established keywords when they fit.

## Rules

- Write keyword in plain text, not bold: `WARNING:` not `**WARNING:**`.
- Same-paragraph lines (no blank line) are attached to and part of callout.
- Blank line ends callout.
- Parenthesized form `(KEYWORD: ...)`: must be single line. Can appear inline
  within another paragraph without blank line separator.
- Guideline: avoid callouts for regular prose or step descriptions careful
  reader would not miss. Prefer rewriting unclear prose over adding markers.

## Examples

Multi-line WARNING — blank line ends callout:

````md
WARNING: Avoid `.opencode/skills/` for team repos — it locks the skill to
OpenCode only and blocks non-OC contributors.

This line is no longer part of the warning.
````

Parenthesized IMPORTANT inline in a paragraph:

````md
Present the draft as a fenced block labeled with the artefact type.
(IMPORTANT: Always use 4 backticks so nested code blocks don't break formatting.)
Ask: *Does this match what you had in mind?*
````
