# Phase:Explore

Delegate deep, pre-spec design maturation to the `design-exploration` skill.
Do not run the exploration loop inline here — the `design-exploration` skill owns it.

## When to offer

- After `Phase:Discover`, when the design is genuinely uncertain.
- Mid-`Phase:Draft` (re-entrant), when a new design fork opens.

## Invocation

Load the `design-exploration` skill, passing:

- `$explodir` — the exploration dir: `$specdir` for a fresh run,
  or a pre-existing exploration dir to resume (e.g. `_WIP_EXPLORATIONS/<slug>/`).
  The skill confirms this path with the user.
- `$name`, `$slug` — the spec's.
- Seed context — what the user asked to explore.
- Mode — a fresh exploration (from `Discover`) or a re-entrant fork (from `Draft`),
  plus the topic label.

The skill runs under its own interaction rules.

## On return

- Read the hub `EXPLORATION-BRIEF.md` topic index.
- Fold settled `Decisions` and `Open threads` into drafting — do not duplicate their content.
- If `$explodir` differs from `$specdir`, move the exploration files into `$specdir`
  at the start of `Phase:Draft` (see <./draft.md>).
- Resume `Phase:Draft`.

Exploration-file freeze and revival are tracked in the hub, not in this phase.

Ready to move to `Phase:Draft`? (say 'next' or similar to proceed)