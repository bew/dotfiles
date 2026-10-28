# Phase:Explore

Delegate deep, pre-spec design maturation to the `design-exploration` skill.
Do not run the exploration loop inline here — the `design-exploration` skill owns it.

## When to offer

- After `Phase:Discover`, when the design is genuinely uncertain.
- Mid-`Phase:Draft` (re-entrant), when a new design fork opens.
- From `maybe-ready` or `ready`, when an open question reopens the design.

## Invocation

First move the spec to the `explo` state, from `$specdir`:
```sh
<skill-dir>/scripts/manage-spec explo
```
Adopt the printed `Session vars`.
Skip the move when the spec is already in `explo`.

Then load the `design-exploration` skill, passing:

- `$specdir` — the spec dir; `design-exploration` adopts it as its `$explodir` without asking.
  Exploration files live here, next to `DISCOVERY.md`.
  Resuming a pre-existing exploration passes that exploration dir instead.
- `$title`, `$slug` — the spec's.
- `$fordraft` = `true` — this spec, so the `Phase:Wrap` exit question can offer `Switch to Draft`.
- Seed context — what the user asked to explore.
- Mode — a fresh exploration (from `Discover`) or a re-entrant fork (from any later state),
  plus the topic label.

The skill runs under its own interaction rules.

## On return

Promotion is gated on an explicit exit signal.
The `design-exploration` `Phase:Wrap` exit question must have been asked, and the user must
have answered with `Switch to Draft`.
A return from the exploration is not itself an exit signal: when the user picked a remaining
topic, stay in `Phase:Explore` and continue on it.
When no such answer is in the conversation, re-ask the exit question per the
`design-exploration` `Phase:Wrap` rules and wait — do not promote.

Promote the spec to `draft`, from `$specdir`:
```sh
<skill-dir>/scripts/manage-spec draft
```
Adopt the printed `Session vars`.

Then:
- Read the hub `EXPLO-BRIEF.md` topic index.
- Fold settled `Decisions` and `Open threads` into drafting — do not duplicate their content.
- Resume `Phase:Draft`.

Exploration-file freeze and revival are tracked in the hub, not in this phase.
