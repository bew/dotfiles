# Work Capture Bug Doc Template

Used only in `capture-bug` mode.
The capture doc must contain the following sections in order.
Omit any optional section that has no qualifying content — do not keep an
empty heading or write filler (e.g. "none", "N/A", "nothing to report").

---

# <one-line symptom>

H1 heading — the bug in one line, stated as what goes wrong.
When the bug is confirmed, prefix the heading with `[CONFIRMED]`: `# [CONFIRMED] <symptom>`.
Leave it untagged when the bug is still open.

<description: what goes wrong, where, and why it matters.
May state what in the session triggered it, as provenance.
Keep it to a short paragraph.>

## Expected

One line: what should happen instead.

## Actual

One line: what happens instead.

## Reproduction

Numbered steps, one line each, enough for a future agent to trigger the bug.
Omit the section only when no reproduction is known, and say so in the description.

## Blockers

Optional — include only when the item has blockers or prerequisites.
Flat bullets, one line each: what must happen first, and why.

## Open questions

Optional — include only when the item has open sub-questions left to resolve.
Flat bullets, one line each: the question, and what it affects.

## Artefacts

Optional — include only when related to the item.
Bullets: `<path|URL>` — one line on why it matters.
