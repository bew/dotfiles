# Spec structure reference

## Section order

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

## H1 status tag

H1 format: `# [STATUS] <Name>`

Status tags and meanings:

| Tag | Meaning |
|---|---|
| `DRAFT` | Active work-in-progress |
| `READY` | Confirmed stable; set manually by user |
| `ABANDONED` | No longer pursued; kept for reference |

Default on creation: `DRAFT`.
All tags other than `DRAFT` are set manually by the user — not by the agent.

## Writing the skeleton

*Create mode only.*
Before filling any section:
write the H1 with `[DRAFT]` status + all confirmed section headings, empty bodies.
Each main section (`##`) likely to surface design decisions gets an empty `### Open Questions` subsection.
Omit `### Open Questions` from Introduction and Terminology — they are not decision surfaces.
If the chosen design has meaningful sub-variants, include a placeholder heading for the optional design-options section (choose a descriptive name — see section order above).

Example skeleton:

```md
# [DRAFT] My System

## Introduction

## Terminology

## API

### Open Questions

## Alternatives & Tradeoffs
```

## Structure rules

**Heading hierarchy**: use `##` for top-level spec sections, `###` for sub-topics within a section.
Do not flatten everything to the same level.

**File splitting**: default to a single `SPEC.md`.
Only extract a companion file when a section is large enough that keeping it inline makes the main spec hard to read.
Companion files supplement — they do not replace readable content in `SPEC.md`.
Before extracting, verify the content type matches the file name.
Different concerns belong in separate files (e.g. CLI behavior and file format are distinct — do not conflate them).

## Related Artifacts section

This section provides contextual pointers to artifacts worth knowing about:
proofs-of-concept, reference implementations, relevant source dirs, design docs, URLs.

This is not a file list.
Describe what the artifact provides or demonstrates —
e.g. "a proof-of-concept showing cross-process handoff lives in `$specdir/poc/`".

When a companion file is already referenced from another section
(e.g. a schema file linked in API), don't repeat it here.

Each entry: name + one-line description of relevance.
Omit if nothing meaningful to note.
