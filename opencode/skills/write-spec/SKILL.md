---
name: write-spec
description: |
  Methodology for drafting technical design specs.
  Load when asked to write, draft, or refine a spec, design doc, architecture note, RFC,
  or similar document for a system, API, protocol, or subsystem.
metadata:
  maintainers: [bew]
---

# Skill: write-spec

## Goal

Produce structured, honest, maintainable technical specs
capturing design decisions, API shape, invariants, and open questions.

## Phases

Three phases, always in order:

1. `Phase:Discover` — gather inputs; establish `$basedir`, `$specdir`, `$specpath`
2. `Phase:Draft` — confirm section structure; write spec; fill sections iteratively
3. `Phase:Review` — in-context review; assess readiness; optionally promote to `_SPECS/`

**Paths used throughout:**

- `$basedir` — base specs directory, either `_WIP_SPECS/` (default) or `_SPECS/` (promoted)
- `$slug` — short kebab-case identifier for this spec, confirmed in `Phase:Discover`
- `$specdir` — `$basedir/<slug>/` — the spec's own directory; contains `SPEC.md` and related files
- `$specpath` — `$specdir/SPEC.md` — the spec file; defined at end of `Phase:Discover`; used in all subsequent phases

The spec's H1 includes a status tag: `# [STATUS] <Name>`
Current status tags: `DRAFT`, `MAYBE-READY`, `READY`, `ABANDONED`
Default on creation: `DRAFT`.
Update in-place as spec evolves.

## 1. `Phase:Discover` — Gather inputs & establish `$specpath`

When entering `Phase:Discover`: read <./refs/phases/discover.md> for full instructions.

## 2. `Phase:Draft` — Write skeleton; fill sections iteratively

When entering `Phase:Draft`: read <./refs/phases/draft.md> for full instructions.

## 3. `Phase:Review` — In-context review pass

When entering `Phase:Review`: read <./refs/phases/review.md> for full instructions.
