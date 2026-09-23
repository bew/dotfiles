---
name: write-spec
description: |
  Methodology for drafting technical design specs.
  Load when asked to write, draft, or refine a spec, design doc, architecture note, RFC,
  or similar document for a system, API, protocol, or subsystem.
  Also load FIRST when a file in context directs agents to load a spec-writing skill.
metadata:
  maintainers: [bew]
---

# Skill: write-spec

## Goal

Produce structured, honest, maintainable technical specs
capturing design decisions, interface shape, invariants, and open questions.

## Phases

Phases, in order (`Explore` is optional):

1. `Phase:Discover` — gather inputs; establish `$basedir`, `$specdir`, `$specpath`
2. `Phase:Explore` _(if design uncertain)_ — delegate to the `design-exploration` skill
3. `Phase:Draft` — confirm section structure; write spec; fill sections iteratively
4. `Phase:Review` — in-context review; assess readiness; optionally promote to `_SPECS/`

**Paths used throughout:**

- `$basedir` — base specs directory, either `_WIP_SPECS/` (default) or `_SPECS/` (promoted)
- `$slug` — short kebab-case identifier for this spec, confirmed in `Phase:Discover`
- `$specdir` — `$basedir/<slug>/` — the spec's own directory; contains `SPEC.md` and related files
- `$specpath` — `$specdir/SPEC.md` — the spec file; defined at end of `Phase:Discover`; used in all subsequent phases

The spec's H1 includes a status tag: `# [STATUS] <Name>`
Current status tags: `DRAFT`, `MAYBE-READY`, `READY`, `ABANDONED`
Default on creation: `DRAFT`.
Update in-place as spec evolves.

## Interaction conventions

Apply in every phase.

**`tell me more`**, **`tell me about …`**, or **`explain …`**:
The user wants an explanation in chat output only — not a spec edit.
Treat it as informational:
- Do not edit `$specpath`.
- Do not add Open Questions entries or change the status tag.
- Answer in chat, then pause and wait for the user to resume.
Whether anything is later folded into the spec is the user's explicit call.

## 1. `Phase:Discover` — Gather inputs & establish `$specpath`

When entering `Phase:Discover`: read <./refs/phases/discover.md> for full instructions.

## 2. `Phase:Explore` — Delegate deep design maturation _(if design uncertain)_

Optional phase. Delegate deep, pre-spec design maturation to the `design-exploration` skill.
Enter when the design is genuinely uncertain — competing models, an undefined central concept.
Skip straight to `Phase:Draft` when the design is settled enough to choose a section skeleton.

When entering `Phase:Explore`: read <./refs/phases/explore.md> for full instructions.

## 3. `Phase:Draft` — Write skeleton; fill sections iteratively

When entering `Phase:Draft`: read <./refs/phases/draft.md> for full instructions.

## 4. `Phase:Review` — In-context review pass

When entering `Phase:Review`: read <./refs/phases/review.md> for full instructions.
