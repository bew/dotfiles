---
name: write-spec
description: |
  Methodology for drafting technical design specs.
  Load when asked to write, draft, or refine a spec, design doc, architecture note, RFC,
  or similar document for a system, API, protocol, or subsystem.
---

## Goal

Produce structured, honest, maintainable technical spec
capturing design decisions, API shape, invariants, and open questions.

## Pre-writing phase (new specs only)

Before drafting any section, gather these inputs:

1. **System name** — what is this thing called?
2. **Problem** — what does it solve, and for whom?
3. **Alternatives considered** — what simpler or existing approaches were weighed?
4. **Inspirations** — any prior art, external systems, or sessions that shaped the design?
5. **Spec file location** — where should spec file live?
   Suggest options: current directory, git root, or let user specify.
6. **POC files** — will there be proof-of-concept or reference implementation files?
   If yes, they default to `<spec-file>-POC/` next to spec file.
   Confirm path with user or let them override.

If user has already supplied most context inline, confirm/waive inputs quickly rather than
asking each one explicitly.

Do not begin writing spec body until all inputs are answered or explicitly waived by user.

## Rules

- Never write full rewrite when targeted edit is requested. Surgical edits only.
- Never paper over unresolved decisions. Surface them in Open Questions section.
- Never mix terminology once terms are defined. Use exact names from Concepts section everywhere.
- Always define all terms in Concepts before using them elsewhere in spec.
- Always include Open Questions section, even if short.
- Always include Positioning section that honestly compares proposed system against simpler alternative.
- When omitting a section, flag it explicitly: name section and state reason it was skipped.
- When a config field's value may depend on runtime state (e.g. cwd, git, loaded plugins), ask
  user whether it should be plain value or function called lazily at first use.
  If it is a function, note in spec: when it is called and whether result is cached.

## Structure

Use this section order.
Omit section only if genuinely not applicable — flag each omission explicitly (see Rules).

1. **Introduction** — context, motivation, use-cases, inspirations (no compression, full prose)
2. **Concepts** — define every term used in spec (full prose, precise)
3. **Naming & IDs** — if system has named/anonymous things, show patterns here
4. **API** — code examples are central; prose explains intent, code shows shape
5. *(domain-specific sections)* — non-obvious invariants each get their own section
6. **Placement / Scope** — where things can/must be defined
7. **`<Feature>` as `<Primitive>`** — if familiar concept expresses itself as primitive in new system, show mapping explicitly
8. **Positioning** — compare against alternatives; include decision criteria
9. **POC** — if POC files exist
10. **Open Questions** — numbered list; unresolved design decisions, tradeoffs not yet settled

## Prose style

- One sentence per line.
  Long sentences may wrap, but next sentence always starts on new line.
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

- Show most complete realistic example, not a toy.
- Preserve honest comments (`-- FIXME`, `-- NOTE`) — they are design signals, not noise.
- If API has multiple forms (named / anonymous, shorthand / full), show all.
- If field has type annotation, show both simple and more-defined type variants if relevant.

## Naming discipline

- Define canonical name for each concept in Concepts.
- Use that exact name everywhere — in prose, code comments, section headings.
- If concept has short internal form (e.g. `P` for provider inside impl code), define at first use.
- Never use synonyms: pick one word and hold it.

## Positioning section

### Single proposed design vs simpler alternative

Structure:

1. Show simplest viable alternative in code (plain module, raw function, etc.).
2. List advantages of plain alternative.
3. List advantages of proposed system.
4. List costs of proposed system.
5. State rough heuristic for when to use each.

### Multiple competing designs

When two or more competing implementations or approaches (rather than one design vs. simpler baseline):

- Give each option short label (e.g. **Option A — resession wrapper**, **Option B — full custom**).
- For each option: show minimal code sketch, list advantages, list costs.
- End with **Decision criteria** paragraph: name concrete conditions under which each option
  wins. Avoid "it depends" without specifying what it depends on.
- If choice is genuinely unresolved, move to Open Questions instead of leaving vague heuristic.

## Open Questions format

Each entry in Open Questions section must include:

- Clear statement of unresolved decision.
- **Blocking** or **Non-blocking** — must this be resolved before implementation starts?
- Brief rationale: what is blocking decision, or what tradeoff makes it non-obvious.

Remove or strike questions once resolved; don't let stale entries accumulate.

Example:

> 1. Should providers be allowed to deregister at runtime?
>    Non-blocking. No clear use-case yet; adding it costs lifecycle complexity that may never pay off.

## POC directory

When POC files exist, place them in POC directory confirmed during pre-writing phase
(default: `<spec-file>-POC/`) and create `POC-README.md` there.

`POC-README.md` contains:
- List of files/directories with one-line description of what each experiments with.
- Status of each distinct piece: e.g. *pseudo-code*, *working*, *partial*, *abandoned*.
- How to run or load it — only if it was actually tested; omit otherwise.
- Concrete impl notes, tradeoffs, and gotchas discovered during experiment.
- Any deviations from spec and why.

What stays in spec, not in `POC-README.md`:
- API shape and pseudo-code sketches.
- Considered implementation directions.
- High-level design thoughts and invariants.

POC directory is for concrete experiments only.
Spec is for design intent.

## Refinement loop

When refining an existing spec draft:

1. Read full current spec first.
2. Apply only requested changes — do not restructure unrelated sections.
3. When user instruction changes a rule, check all sections referencing that rule and update for consistency.
4. After edits, verify prose still follows sentence-per-line format in touched sections.
   If any violation found, flag to user and ask: fix silently / fix with confirmation / leave as-is.

Always use `edit` tool for spec changes after initial write.
Never overwrite file with full rewrite.
