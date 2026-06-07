---
name: write-spec
description: |
  Methodology for drafting technical design specs.
  Load when asked to write, draft, or refine a spec, design doc, architecture note, RFC,
  or similar document for a system, API, protocol, or subsystem.
---

## Goal

Produce a structured, honest, and maintainable technical spec
that captures design decisions, API shape, invariants, and open questions.

## Pre-writing phase (new specs only)

Before drafting any section, gather these inputs:

1. **System name** — what is this thing called?
2. **Problem** — what does it solve, and for whom?
3. **Alternatives considered** — what simpler or existing approaches were weighed?
4. **Inspirations** — any prior art, external systems, or sessions that shaped the design?

Do not begin writing the spec body until all four are answered or explicitly waived by the user.

## Rules

- Never write a full rewrite when a targeted edit is requested. Surgical edits only.
- Never paper over unresolved decisions. Surface them in the Open Questions section.
- Never mix terminology once terms are defined. Use exact names from the Concepts section everywhere.
- Always define all terms in Concepts before using them elsewhere in the spec.
- Always include an Open Questions section, even if short.
- Always include a Positioning section that honestly compares the proposed system against a simpler alternative.
- When omitting a section, flag it explicitly: name the section and state the reason it was skipped.

## Structure

Use this section order.
Omit a section only if genuinely not applicable — and flag each omission explicitly (see Rules).

1. **Introduction** — context, motivation, use-cases, inspirations (no compression, full prose)
2. **Concepts** — define every term used in the spec (full prose, precise)
3. **Naming & IDs** — if the system has named/anonymous things, show the patterns here
4. **API** — code examples are central; prose explains intent, code shows shape
5. *(domain-specific sections)* — non-obvious invariants each get their own section
6. **Placement / Scope** — where things can/must be defined
7. **`<Feature>` as `<Primitive>`** — if a known existing thing maps onto the new system, show it explicitly
8. **Positioning Question** — compare against the simplest viable alternative; include a heuristic
9. **Open Questions** — numbered list; unresolved design decisions, tradeoffs not yet settled

## Prose style

- One sentence per line.
  Long sentences may wrap, but the next sentence always starts on a new line.
- Introduction and Concepts: full prose, no compression.
- Other sections: terse, imperative, concrete.
- Use `NOTE:` / `FIXME:` / `WARNING:` for callouts.

Bad:
```text
This is a sentence. This is another sentence
that wraps and continues here.
```

Good:
```text
This is a sentence.
This is another sentence that wraps and continues here.
```

## API sections

- Show the most complete realistic example, not a toy.
- Preserve honest comments (`-- FIXME`, `-- NOTE`) — they are design signals, not noise.
- If the API has multiple forms (named / anonymous, shorthand / full), show all.
- If a field has a type annotation, show both simple and more-defined type variants if relevant.

## Naming discipline

- Define the canonical name for each concept in Concepts.
- Use that exact name everywhere — in prose, code comments, section headings.
- If a concept has a short internal form (e.g. `P` for provider inside impl code), define it at first use.
- Never use synonyms: pick one word and hold it.

## Positioning section

Structure:

1. Show the simplest viable alternative in code (a plain module, a raw function, etc.).
2. List advantages of the plain alternative.
3. List advantages of the proposed system.
4. List costs of the proposed system.
5. State a rough heuristic for when to use each.

## Open Questions format

Each entry in the Open Questions section must include:

- A clear statement of the unresolved decision.
- A brief rationale: what is blocking the decision, or what tradeoff makes it non-obvious.

Example:

> 1. Should providers be allowed to deregister at runtime?
>    Blocked by: no clear use-case yet; adding it costs lifecycle complexity that may never pay off.

## Refinement loop

When refining an existing spec draft:

1. Read the full current spec first.
2. Apply only the requested changes — do not restructure unrelated sections.
3. When a comment changes a rule, check all sections that reference that rule and update them for consistency.
4. After edits, verify prose still follows sentence-per-line format in touched sections.
   If any violation is found, flag it to the user and ask: fix silently / fix with confirmation / leave as-is.
