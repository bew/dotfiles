---
name: write-spec-noninteractive-standalone
description: |
  Fully self-contained, non-interactive methodology for drafting or updating technical design specs.
  Load when asked to write, draft, refine, or update a spec, design doc, architecture note, RFC,
  or similar document for a system, API, protocol, or subsystem.
  Designed for use in tools without interactive loops (Perplexity, ChatGPT, etc.).
  All instructions are inlined — no external files required.
  Runs a full pass without mid-pass checkpoints; batches all questions at the end.
  Do NOT auto-load unless requested.
metadata:
  maintainers: [bew]
---

# Skill: write-spec-noninteractive-standalone

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

Before filling any section:
write the H1 with `[DRAFT]` status + all confirmed section headings, empty bodies.
Each main section (`##`) likely to surface design decisions gets an empty `### Open Questions` subsection.
Omit `### Open Questions` from Introduction and Terminology — they are not decision surfaces.
If the chosen design has meaningful sub-variants, include a placeholder heading for the optional design-options section (choose a descriptive name — see section order below).

H1 format: `# [DRAFT] <Name>`

Example skeleton:

```md
# [DRAFT] My System

## Introduction

## Terminology

## API

### Open Questions

## Alternatives & Tradeoffs
```

**Heading hierarchy**: use `##` for top-level spec sections, `###` for sub-topics within a section.
Do not flatten everything to the same level.

**File splitting**: default to a single `SPEC.md`.
Only extract a companion file when a section is large enough that keeping it inline makes the main spec hard to read.
Companion files supplement — they do not replace readable content in `SPEC.md`.
Before extracting, verify the content type matches the file name.
Different concerns belong in separate files (e.g. CLI behavior and file format are distinct — do not conflate them).

## 4. `Phase:Fill` — fill sections

### Section order

Write sections in this order.
Omit a section only if genuinely not applicable — state the section name and reason for omission.

1. **Introduction** — context, motivation, use-cases, inspirations (full prose, no compression)
2. **Terminology** — define every term used in spec; mark each as `(new!)`, `(updated!)`, or well-known
3. **Naming & IDs** — if system has named/anonymous things, show patterns here
4. **API** — code examples are central; prose explains intent, code shows shape
5. *(domain-specific sections)* — non-obvious invariants each get their own section
6. **Placement / Scope** — where things can/must be defined
7. **`<Feature>` as `<Primitive>`** — if familiar concept maps to a primitive in new system, show it explicitly
8. *(optional)* — different options within the chosen design; include tradeoffs and decision criteria to help choose between them.
   Covers any kind of design-internal alternative: implementation approaches, configuration strategies, protocol choices, library choices, API surface variants, algorithm selection, storage strategies, etc.
   Omit if the chosen design has no meaningful sub-variants.
9. **Alternatives & Tradeoffs** — compares the whole spec against complete alternative directions; include decision criteria
10. **Related artifacts** — contextual pointers to related artifacts

### Mode behavior

*Create mode*: fill all sections sequentially without pausing.

*Update mode*: apply only the requested changes — do not restructure unrelated sections.
When a change affects multiple sections, update all affected sections for consistency.
After edits, verify prose still follows sentence-per-line format in touched sections.
If a violation is found, fix it silently.

### Rules

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

### Prose style

- One sentence per line.
  Long sentences may wrap, but next sentence always starts on a new line.
- Introduction and Terminology: full prose, no compression.
- Other sections: terse, imperative, concrete.
- Use `NOTE:` / `FIXME:` / `WARNING:` for callouts.

Bad:
```md
This is a sentence. This is another sentence
that wraps and continues here.
```

Good:
```md
This is a sentence.
This is another sentence that wraps and continues here.
```

### Terminology entries

- `**Some New Thing** (new!): The definition…`
- `**Some Updated Thing** (updated!):` The revised definition — state what changed, or mark `(replaced!)` if fully superseded.
- Well-known terms: no need to re-define; one-line note or omit entirely.

A term may define a short name (e.g. `ExtPoint` for `Extension Point`).
Short names reduce token count and avoid horizontal overflow.
If a short name is defined, use it consistently throughout — never alternate with the full name.

### Naming discipline

- Define canonical name for each concept in Terminology.
- Use that exact name everywhere — in prose, code comments, section headings.
- Never use synonyms: pick one word and hold it.

### API sections

- Show most complete realistic example, not a toy.
- Preserve honest comments (`-- FIXME`, `-- NOTE`) — they are design signals.
- If API has multiple forms (named / anonymous, shorthand / full), show all.
- If a field has a type annotation, show both simple and more-defined type variants if relevant.

### Alternatives & Tradeoffs section

**Scope:** compare whole-spec with alternative directions.
For localized alternatives within the chosen direction (affecting only one-two sections),
place them in the optional section 8 instead.

Do not go deep into alternative directions — mention them and their tradeoffs
only if they were discussed with the user during discovery.
This section is a concise comparison, not an exhaustive exploration.

**Single proposed design vs simpler alternative:**

1. Show simplest viable alternative in code.
2. List advantages of plain alternative.
3. List advantages of proposed design.
4. List costs of proposed design.
5. State rough heuristic for when to use each.

**Multiple competing designs:**

- Give each option a short label (e.g. **Option A — session wrapper**).
- For each: show minimal code sketch, list advantages, list costs.
- End with **Decision criteria**: name concrete conditions under which each option wins.
  Avoid "it depends" without specifying what it depends on.
- If genuinely unresolved: move to Open Questions.

### Related Artifacts section

This section provides contextual pointers to artifacts worth knowing about:
proofs-of-concept, reference implementations, relevant source dirs, design docs, URLs.

This is not a file list.
Describe what the artifact provides or demonstrates —
e.g. "a proof-of-concept showing cross-process handoff lives in `$specdir/poc/`".

When a companion file is already referenced from another section
(e.g. a schema file linked in API), don't repeat it here.

Each entry: name + one-line description of relevance.
Omit if nothing meaningful to note.

### Open Questions format

Open Questions appear throughout the spec — in any `### Open Questions` subsection under a section
where design decisions remain unresolved.
They are not specific to Alternatives & Tradeoffs.

Each entry must include:

- Clear statement of unresolved decision.
- **Blocking** or **Non-blocking** — must this be resolved before implementation starts?
- Brief rationale: what is blocking the decision, or what tradeoff makes it non-obvious.

Remove or strike questions once resolved.

Example:

> 1. Should providers be allowed to deregister at runtime?
>    Non-blocking. No clear use-case yet; adding it costs lifecycle complexity that may never pay off.

## 5. `Phase:Defer` — review, assess readiness, output questions

### Review pass

After all sections are filled, check:

- All Open Questions are marked **Blocking** or **Non-blocking**
- Introduction and Terminology are complete prose (no skeleton placeholders)
- All terms used in spec are defined in Terminology before first use
- No terminology drift — single canonical name used everywhere for each concept
- No empty `### Open Questions` subsections remain
- `FIXME:` callouts are allowed as design signals — they do not block readiness.
  If a callout is not specific to its surrounding text, move it to Open Questions instead.
- Prose in touched sections follows sentence-per-line format
- Status tag in H1 reflects current state (set to `[DRAFT]` on creation; preserved on updates)

Flag any issues found; note them in the deferred questions block if they require user input.

### H1 status tag

H1 format: `# [STATUS] <Name>`

| Tag | Meaning |
|---|---|
| `DRAFT` | Active work-in-progress |
| `READY` | Confirmed stable; set manually by user |
| `ABANDONED` | No longer pursued; kept for reference |

All tags other than `DRAFT` are set manually by the user — not by the agent.

### Readiness criteria

Assess readiness after the review pass.
State which criteria pass and which fail — do not update the H1 tag.

1. Introduction and Terminology are complete prose — no placeholders.
2. Any unfocused `FIXME:` callouts moved to Open Questions (focused ones may remain).
3. All Open Questions marked **Blocking** or **Non-blocking**.
4. No **Blocking** Open Questions remain unresolved.
5. Alternatives & Tradeoffs section present and honest.
6. No synonym drift — all terms defined in Terminology before use.
7. Spec reflects current design intent — surface as a deferred question: *"Does this spec reflect your current design intent?"*

If all criteria 1–6 pass and the only deferred question is criterion 7:
note that the spec may be ready to mark `[READY]` manually once the author confirms design intent.
Then output the deferred questions block.

### Deferred questions

After the full draft is written and readiness assessed,
output a single batched list of all questions that require user input.
Do not ask questions mid-pass.

Format:

```md
## Questions for you

1. <question about unresolved design decision>
2. <question about missing input>
3. …
```

Include only genuinely open questions.
Omit if no questions remain.
