---
name: write-spec
description: |
  Methodology for drafting technical design specs.
  Load when asked to write, draft, or refine a spec, design doc, architecture note, RFC,
  or similar document for a system, API, protocol, or subsystem.
  Also load when updating an existing spec, or moving one between lifecycle states.
  Also load FIRST when a file in context directs agents to load a spec-writing skill.
metadata:
  maintainers: [bew]
---

# Skill: write-spec

## Goal

Produce structured, honest, maintainable technical specs
capturing design decisions, interface shape, invariants, and open questions.

## Entry gate

No spec file may be written before `manage-spec init` ran and printed `$specpath`.
`Phase:Discover` owns that step.
The only exception is a legacy layout, which starts with `manage-spec migrate`.

An approved plan or a settled design settles content only.
It waives `Phase:Explore`, never `Phase:Discover`: the discovery notes still get written, and the
section skeleton still gets confirmed.

A repo that already holds specs does not short-circuit the lifecycle.
A legacy `_WIP_SPECS/` or `_SPECS/` layout goes through `manage-spec migrate`; never write a
`SPEC.md` into it by hand.

## Phases

Phases, in order (`Explore` is optional):

1. `Phase:Discover` — gather inputs; create the spec dir in `discovery`; capture the paths
2. `Phase:Explore` _(if design uncertain)_ — move to `explo`; delegate to `design-exploration`;
   leave only on its explicit `Switch to Draft` answer
3. `Phase:Draft` — promote to `draft`; confirm structure; write spec; fill sections iteratively
4. `Phase:Review` — in-context review; assess readiness; transition the spec

**Vars supplied by the caller:**

- `$slug` — short kebab-case identifier for this spec, confirmed in `Phase:Discover`
- `$title` — the spec's human-readable title

**Vars printed by `manage-spec`:**

- `$slug` — re-reported when `rename` changes it
- `$specdir` — the spec's own directory
- `$specpath` — the spec file to read and edit

`init` prints them first, and every command that moves or renames the spec re-reports them.
Take them from the tool output; never derive them yourself.

The lifecycle tool is `<skill-dir>/scripts/manage-spec`; read <./refs/lifecycle.md>.

`manage-spec` prints a `Session vars` block listing the variables that changed —
use what it prints, and keep values that did not change.
`Session vars: unchanged` means every value stays as it was.

The spec's H1 carries a status tag: `# [STATUS] <Title>`
Current status tags: `DISCOVERY`, `EXPLO`, `DRAFT`, `MAYBE-READY`, `READY`, `ABANDONED`.
`manage-spec` owns the tag, the loader paragraph, and the directory name — never edit any of them,
and never move a spec dir by hand.

## Interaction conventions

Apply in every phase.

**`tell me more`**, **`tell me about …`**, or **`explain …`**:
The user wants an explanation in chat output only — not a spec edit.
Treat it as informational:
- Do not edit `$specpath`.
- Do not add Open Questions entries or change the status tag.
- Answer in chat, then pause and wait for the user to resume.
Whether anything is later folded into the spec is the user's explicit call.

**Asking about Open Questions** (via the `question` tool):
The last message the user sees before the `question` batch must carry enough context
to understand every question in it — the tool's own titles are easy to miss.
- Name the section and the OQ entry each question refers to.
- When one batch asks several OQs, contextualize all of them — not just the first.
- Never emit an OQ `question` call with no contextualizing message before it.
This applies to OQ asks only, not to every question batch.

## 1. `Phase:Discover` — Gather inputs & create the spec directory

When entering `Phase:Discover`: read <./refs/phases/discover.md> for full instructions.

## 2. `Phase:Explore` — Delegate deep design maturation _(if design uncertain)_

Optional phase. Delegate deep, pre-spec design maturation to the `design-exploration` skill.
Enter when the design is genuinely uncertain — competing models, an undefined central concept.
Skip straight to `Phase:Draft` when the design is settled enough to choose a section skeleton.

When entering `Phase:Explore`: read <./refs/phases/explore.md> for full instructions.

`Phase:Explore` ends only on the user's explicit `Switch to Draft` answer to the
`design-exploration` `Phase:Wrap` exit question.
Until that answer exists, never run `manage-spec draft`.
A frozen topic index, a completed-looking exploration, or the agent's own suggestion to exit are
not exit signals.

This gate is skill-enforced: `manage-spec draft` does not check it.
The transition table in <./refs/lifecycle.md> is the authority for the states; this rule is the
authority for entering `draft`.

## 3. `Phase:Draft` — Write skeleton; fill sections iteratively

When entering `Phase:Draft`: read <./refs/phases/draft.md> for full instructions.

## 4. `Phase:Review` — In-context review pass

When entering `Phase:Review`: read <./refs/phases/review.md> for full instructions.
