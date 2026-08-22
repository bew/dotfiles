# Spec Structure

Reference for section order, prose rules, API conventions,
Alternatives & Tradeoffs, and Open Questions format.

## Layout

Each spec lives at `$specpath` = `$specdir/SPEC.md`, where `$specdir` = `$basedir/<slug>/`.
Related artifacts (examples, experiments, reference impls, external links) go next to the spec file:

```
$basedir/
└── <slug>/              ← $specdir
    ├── SPEC.md          ← $specpath — the spec
    ├── <related-file>   ← any companion files, no nesting required
    └── <sub-dir>/       ← sub-directories if grouping is useful
```

Everything lives alongside `SPEC.md` — no separate subdirectory convention.

## Section order

Use this order.
Omit a section only if genuinely not applicable —
flag each omission explicitly (name section + reason).

1. **Introduction** — context, motivation, use-cases, inspirations (full prose, no compression)
2. **Terminology** — define every term used in spec (full prose, precise);
   mark each entry as new or updated (see Terminology entries below)
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

Open Questions are per-section `### Open Questions` subsections, placed at end of each `##` section that surfaces design decisions.
There is no global Open Questions section at end of spec.
See <./phases/draft.md> for skeleton and pruning rules.

## Terminology entries

Each entry must indicate whether the term is new, updated, or well-known:

- `**Some New Thing** (new!): The definition…`
- `**Some Updated Thing** (updated!):` The revised definition — explicitly state what part changed, or mark as `(replaced!)` if the old meaning is fully superseded.
- Well-known terms (standard, widely understood): no need to re-define;
  a one-line note referencing the accepted meaning is enough,
  or omit entirely if context makes it obvious.

### Short names

A term may define a short name (e.g. `ExtPoint` for `Extension Point`).
Short names reduce token count in prose and avoid horizontal overflow in code comments.
Short names are optional — always validate with user before adopting one
(judge whether it adds clarity or just obscures).
If a short name is defined, it must be used consistently throughout the spec
(not interchanged with the full name).

## Prose style

- One sentence per line.
  Long sentences may wrap, but next sentence always starts on a new line.
- Introduction and Terminology: full prose, no compression.
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

## Naming discipline

- Define canonical name for each concept in Terminology.
- Use that exact name everywhere — in prose, code comments, section headings.
- If concept has short internal form (e.g. `P` for provider inside impl), define at first use.
- Never use synonyms: pick one word and hold it.

## API sections

- Show most complete realistic example, not a toy.
- Preserve honest comments (`-- FIXME`, `-- NOTE`) — they are design signals, not noise.
- If API has multiple forms (named / anonymous, shorthand / full), show all.
- If a field has a type annotation, show both simple and more-defined type variants if relevant.

## Alternatives & Tradeoffs section

**Scope:** compare whole-spec with alternative directions.
For localized alternatives within the chosen direction (affecting only one-two sections),
place them in the optional section 8 instead.

Do not go deep into alternative directions — mention them and their tradeoffs
only if they were discussed with the user during discovery.
This section is a concise comparison, not an exhaustive exploration.

### Single proposed design vs simpler alternative

Structure:

1. Show simplest viable alternative in code (plain module, raw function, etc.).
2. List advantages of plain alternative.
3. List advantages of proposed design.
4. List costs of proposed design.
5. State rough heuristic for when to use each.

### Multiple competing designs

When two or more competing implementations or approaches:

- Give each option a short label (e.g. **Option A — session wrapper**, **Option B — full custom**).
- For each option: show minimal code sketch, list advantages, list costs.
- End with **Decision criteria**: name concrete conditions under which each option wins.
  Avoid "it depends" without specifying what it depends on.
- If choice is genuinely unresolved, move to Open Questions instead of leaving a vague heuristic.

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

## Open Questions format

Each entry must include:

- Clear statement of unresolved decision.
- **Blocking** or **Non-blocking** — must this be resolved before implementation starts?
- Brief rationale: what is blocking the decision, or what tradeoff makes it non-obvious.

Remove or strike questions once resolved — do not let stale entries accumulate.

Example:

> 1. Should providers be allowed to deregister at runtime?
>    Non-blocking. No clear use-case yet; adding it costs lifecycle complexity that may never pay off.
