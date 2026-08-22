---
name: write-spec-noninteractive
description: |
  Standalone, non-interactive methodology for drafting or updating technical design specs.
  Load when asked to write, draft, refine, or update a spec, design doc, architecture note, RFC,
  or similar document for a system, API, protocol, or subsystem.
  Designed for use in tools without interactive loops (Perplexity, ChatGPT, etc.).
  Runs a full pass without mid-pass checkpoints; batches all questions at the end.
  Do NOT auto-load unless requested.
metadata:
  maintainers: [bew]
---

# Skill: write-spec-noninteractive

## Goal

Produce or update a structured, honest, maintainable technical spec in a single pass,
capturing design decisions, API shape, invariants, and open questions.
Do not pause for user checkpoints mid-pass.
Any question that arises during drafting must be deferred — added to the batched questions block at the end of the pass.

Two kinds of questions exist in this workflow — keep them distinct:

- **Spec open questions** — unresolved design decisions captured *inside* the spec
  in `### Open Questions` subsections, visible to future readers.
- **Deferred questions for you** — questions for the user, batched in a `## Questions for you` block
  at the end of the agent's output, not written into the spec itself.

## 1. `Phase:Detect` — detect mode, collect inputs

Detect mode from the user's request:

- **Create** — no existing spec; write from scratch.
- **Update** — existing spec content provided; apply only requested changes.

Collect inputs (infer what you can; defer the rest to `Phase:Defer`):

- **Name** — what is this spec about?
- **Slug** — short kebab-case identifier; derive from name if not given.
- **Problem** — what does it solve, and for whom?
- **Inspirations** — prior art, external systems, or prior sessions that shaped the design.
- **Terminology section preference** (via Global OQ) — infer candidate terms;
   decided in `Phase:Defer`.

If the user has supplied context inline, extract inputs directly — do not ask one by one.
If the prompt contains conflicting or ambiguous design signals
(e.g. two incompatible approaches described as if both wanted):
do not pick one silently — surface the conflict in `Phase:Defer`.

## 2. `Phase:Locate` — suggest output path

Suggest filename: `<slug>/SPEC.md`.
State the suggested path at the top of the output before any content.
Use `write` for initial creation.
Use `edit` for all subsequent changes.

## 3. `Phase:Skeleton` — write skeleton (Create mode only)

*Create mode only.*

Read <./refs/spec-structure.md> for:
- Section order and what to omit
- H1 status tag format and meaning, including skill loader meta-paragraph placement
- How to write the skeleton
- Heading hierarchy and file-splitting rules

## 4. `Phase:Fill` — fill sections

Read <./refs/writing-guidelines.md> for prose style, API section rules, and naming discipline.
Read <./refs/terminology-and-key-concepts.md> for terminology entry format.
Read <./refs/open-questions.md> for spec open question format and placement.
Read <./refs/alternatives-and-tradeoffs.md> for how to write the Alternatives & Tradeoffs section.

*Create mode*: fill all sections sequentially without pausing.

*Update mode*: apply only the requested changes — do not restructure unrelated sections.
When a change affects multiple sections, update all affected sections for consistency.
After edits, verify prose still follows sentence-per-line format in touched sections.
If a violation is found, fix it silently.

In both modes:
- Add spec open questions to the relevant section's `### Open Questions` subsection immediately as they arise.
  Do not defer spec open questions to the end — they belong in the spec.
- Never write a full rewrite when a targeted edit is requested. Surgical edits only.
- When omitting a section: name it and state why.
- When a config field's value may depend on runtime state:
  note the uncertainty in the spec and add a spec open question
  ("should this be a plain value or a lazy function? if a function, is result cached?").

After all sections are filled (or updates applied):
- Prune empty `### Open Questions` subsections.
- Write: `Draft written to <path> — open to inspect.`

## 5. `Phase:Defer` — review, assess readiness, output questions

Read <./refs/review-and-readiness.md> for the review checklist, readiness criteria,
and deferred questions format.

Include a deferred question about the Terminology & Key Concepts section:
the decision is tracked via the Global Open Questions entry in the skeleton
(see <./refs/spec-structure.md> — Global Open Questions).
Infer candidate terms from the spec content
(scan for distinct entities, non-standard terms, acronyms, external systems —
see <./refs/terminology-and-key-concepts.md> for candidate inference rules)
and list the inferred candidates in the batched deferred questions
so the user can confirm, reject, or extend them.
If user confirms: update the spec (two-pass — insert section, fill it, re-check readiness).
If user declines: no changes needed — mark the Global OQ entry as resolved.
