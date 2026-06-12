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
5. **Spec file location** — where should the spec file live?
   Suggest options: current directory, git root, or let the user specify.
6. **POC files** — will there be proof-of-concept or reference implementation files?
   If yes, they default to `<spec-file>-POC/` next to the spec file.
   Confirm the path with the user or let them override it.

If the user has already supplied most context inline, confirm/waive the inputs quickly rather than
asking each one explicitly.

Do not begin writing the spec body until all inputs are answered or explicitly waived by the user.

## Rules

- Never write a full rewrite when a targeted edit is requested. Surgical edits only.
- Never paper over unresolved decisions. Surface them in the Open Questions section.
- Never mix terminology once terms are defined. Use exact names from the Concepts section everywhere.
- Always define all terms in Concepts before using them elsewhere in the spec.
- Always include an Open Questions section, even if short.
- Always include a Positioning section that honestly compares the proposed system against a simpler alternative.
- When omitting a section, flag it explicitly: name the section and state the reason it was skipped.
- When a config field's value may depend on runtime state (e.g. cwd, git, loaded plugins), ask the
  user whether it should be a plain value or a function called lazily at first use.
  If it is a function, note in the spec: when it is called and whether the result is cached.

## Structure

Use this section order.
Omit a section only if genuinely not applicable — and flag each omission explicitly (see Rules).

1. **Introduction** — context, motivation, use-cases, inspirations (no compression, full prose)
2. **Concepts** — define every term used in the spec (full prose, precise)
3. **Naming & IDs** — if the system has named/anonymous things, show the patterns here
4. **API** — code examples are central; prose explains intent, code shows shape
5. *(domain-specific sections)* — non-obvious invariants each get their own section
6. **Placement / Scope** — where things can/must be defined
7. **`<Feature>` as `<Primitive>`** — if a familiar concept expresses itself as a primitive in the new system, show the mapping explicitly
8. **Positioning** — compare against alternatives; include decision criteria
9. **POC** — if POC files exist
10. **Open Questions** — numbered list; unresolved design decisions, tradeoffs not yet settled

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

### Single proposed design vs simpler alternative

Structure:

1. Show the simplest viable alternative in code (a plain module, a raw function, etc.).
2. List advantages of the plain alternative.
3. List advantages of the proposed system.
4. List costs of the proposed system.
5. State a rough heuristic for when to use each.

### Multiple competing designs

When there are two or more competing implementations or approaches (rather than one design vs. a
simpler baseline):

- Give each option a short label (e.g. **Option A — resession wrapper**, **Option B — full custom**).
- For each option: show a minimal code sketch, list advantages, list costs.
- End with a **Decision criteria** paragraph: name the concrete conditions under which each option
  wins. Avoid "it depends" without specifying what it depends on.
- If the choice is genuinely unresolved, move it to Open Questions instead of leaving a vague
  heuristic.

## Open Questions format

Each entry in the Open Questions section must include:

- A clear statement of the unresolved decision.
- **Blocking** or **Non-blocking** — must this be resolved before implementation starts?
- A brief rationale: what is blocking the decision, or what tradeoff makes it non-obvious.

Remove or strike questions once resolved; don't let stale entries accumulate.

Example:

> 1. Should providers be allowed to deregister at runtime?
>    Non-blocking. No clear use-case yet; adding it costs lifecycle complexity that may never pay off.

## POC directory

When POC files exist, place them in the POC directory confirmed during the pre-writing phase
(default: `<spec-file>-POC/`) and create a `POC-README.md` there.

`POC-README.md` contains:
- List of files/directories with a one-line description of what each experiments with.
- Status of each distinct piece: e.g. *pseudo-code*, *working*, *partial*, *abandoned*.
- How to run or load it — only if it was actually tested; omit otherwise.
- Concrete impl notes, tradeoffs, and gotchas discovered during the experiment.
- Any deviations from the spec and why.

What stays in the spec, not in `POC-README.md`:
- API shape and pseudo-code sketches.
- Considered implementation directions.
- High-level design thoughts and invariants.

The POC directory is for concrete experiments only.
The spec is for design intent.

## Refinement loop

When refining an existing spec draft:

1. Read the full current spec first.
2. Apply only the requested changes — do not restructure unrelated sections.
3. When a user instruction changes a rule, check all sections that reference that rule and update them for consistency.
4. After edits, verify prose still follows sentence-per-line format in touched sections.
   If any violation is found, flag it to the user and ask: fix silently / fix with confirmation / leave as-is.

Always use the Edit tool for spec changes after the initial write.
Never overwrite the file with a full rewrite.
