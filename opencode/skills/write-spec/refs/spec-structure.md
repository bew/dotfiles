# Spec Structure

Reference for section order, Alternatives & Tradeoffs, and Open Questions format.

## Layout

`$specpath` is the spec file to read and edit inside `$specdir`, both printed by `manage-spec`
(see <./lifecycle.md>).
It is `SPEC.md` from `init` on.
Related artifacts (examples, experiments, reference impls, external links) go next to the spec
file:
```
$specdir/
├── SPEC.md                   ← the spec, carrying the status tag
├── DISCOVERY.md              ← discovery notes, untagged
├── EXPLO-BRIEF.md            ← hub: exploration motivation + topic index
├── EXPLO-<topic>.md          ← one per exploration topic
├── <related-file>            ← any companion files, no nesting required
└── <sub-dir>/                ← sub-directories if grouping is useful
```

Everything lives alongside the spec file — no separate subdirectory convention.
The four boxes above are the shape a spec acquires over its life, not a fixed minimum:
a legacy spec migrated straight into `draft` may hold only `SPEC.md`.

`DISCOVERY.md` and the exploration files are pre-spec design material.
A topic freezes in the hub once folded into `SPEC.md`; re-entry may revive it,
or start a new topic file when the direction is completely different.
`DISCOVERY.md` holds the gathered inputs; it never carries the status tag.

## Frontmatter block

`manage-spec init` opens `SPEC.md` with a fenced block above the H1:
```md
---
created-at: 20261028T1759
---

# [DISCOVERY] <title>
```
- `created-at` — local date and time at `init`, `YYYYMMDDThhmm`.
  No tool regenerates or invents one: a spec created before the block existed keeps none.
- The block must open on line 1 and close on the next `---` line; a blank line separates it from
  the H1. An unclosed fence is refused rather than guessed at.

`manage-spec` preserves the block on every rewrite and never edits its keys.
Add further keys by hand only when a consumer exists for them.

## Section order

Use this order.
Omit a section only if genuinely not applicable, or when the author explicitly asks to.
Flag each omission explicitly (name section + reason).

Exception: Terminology & Key Concepts (section 2) is omitted by default.
The "Global Open Questions" tracks whether it is needed — see <./terminology-and-key-concepts.md>.

1. **Introduction** — context, motivation, use-cases, inspirations (full prose, no compression)
2. **Terminology & Key Concepts** (optional — resolved via Global Open Questions).
   See <./terminology-and-key-concepts.md> for entry format and guidance.
3. **Naming & IDs** — if system has named/anonymous things, show patterns here
4. **Interface / How to use** — the primary user-facing interface: CLI, API, config format, etc.
   Show how to invoke or interact with the thing.
   Use subsections for complex interfaces (e.g. one per subcommand for a CLI).
5. *(domain-specific sections)* — non-obvious invariants each get their own section
6. **Placement / Scope** — where things can/must be defined
7. **`<Feature>` as `<Primitive>`** — if familiar concept maps to a primitive in new system, show it explicitly
8. *(optional)* — different options within the chosen design; include tradeoffs and decision criteria to help choose between them.
   Covers any kind of design-internal alternative:
   implementation approaches, configuration strategies, protocol choices, library choices,
   API surface variants, algorithm selection, storage strategies, etc.
   Omit if the chosen design has no meaningful sub-variants.
9. **Alternatives & Tradeoffs** — compares the whole spec against complete alternative directions;
   include decision criteria. May take the compact or dropped form, see <§alt-tradeoff-forms>.
10. **Related artifacts** — contextual pointers to related artifacts

**Global Open Questions** — unnumbered, appended until the spec reaches `READY`, then pruned when
empty (see <./phases/review.md>).
Default entries included verbatim in skeleton (see <./phases/draft.md>).
Entries default to **Non-blocking** and may escalate to **Blocking** during review.
See Open Questions format below.

Open Questions are per-section `### Open Questions` subsections, placed at end of each `##` section that surfaces design decisions.
See <./phases/draft.md> for skeleton and pruning rules.

## Open Questions format

Two kinds of open questions exist in a spec:

**Per-section Open Questions** — `### Open Questions` at end of any `##` section
that surfaces design decisions. These are specific to that section's domain.

**Global Open Questions** — `## Global Open Questions` at end of spec.
Covers broad unresolved decisions that span multiple sections.
They may escalate to **Blocking** during review if the reviewer judges them critical.

Each entry must include:

- Clear statement of unresolved decision.
- **Blocking** or **Non-blocking** — must this be resolved before implementation starts?
- Brief rationale: what is blocking the decision, or what tradeoff makes it non-obvious.

Within each Open Questions subsection, list **Blocking** entries before **Non-blocking** ones.

Remove or strike questions once resolved — do not let stale entries accumulate.
Deferred OQs are intentionally retained and may be revisited later —
keeping them is not a review failure.

Example:

> 1. Should providers be allowed to deregister at runtime?
>    Non-blocking. No clear use-case yet; adding it costs lifecycle complexity that may never pay off.

## Alternatives & Tradeoffs section

**Scope:** compare whole-spec with alternative directions.
For localized alternatives within the chosen direction (affecting only one-two sections),
place them in the optional section 8 instead.

Do not go deep into alternative directions — mention them and their tradeoffs
only if they were discussed with the user during discovery.
This section is a concise comparison, not an exhaustive exploration.

### Forms
<!-- §alt-tradeoff-forms -->

Full is the drafting default.
`Phase:Review` offers the choice when the section is missing or thin.

- **Full** — write it per one of the two structures below.
- **Compact** — bullets only: chosen design (one line), simplest alternative (one line),
  one advantage of the alternative, one cost of the design, one-line decision criterion.
  No code sketches, no per-option breakdown.
  Must name a concrete cost of the proposed design — a compact form without one
  is not a comparison.
- **Dropped** — omit the section and flag it in place:
  `<!-- NOTE: Alternatives & Tradeoffs — omitted: <reason> -->`
  Requires explicit author agreement — the flag records that agreement.

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
(e.g. a schema file linked in Interface / How to use), don't repeat it here.

Each entry: name + one-line description of relevance.
Omit if nothing meaningful to note.
