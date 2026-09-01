---
name: plan-milestones
description: |
  Load when user asks to plan, create, or update project milestones.
  Examples: "plan milestones", "break this into milestones", "create MILESTONES.md",
  "write milestones for this spec", "add a milestone", "update milestones".
metadata:
  maintainers: [bew]
---

## Goal

Produce a well-ordered `MILESTONES.md` where every milestone is a thin, independently verifiable
vertical slice, progressing make-it-work → make-it-right → make-it-fast.

## Setup — resolve inputs

Determine the following from whatever is in context (user message, prior context, or defaults):
- **$specpath**: where the project spec lives (file path, directory, or glob).
  Required — stop and ask user if absent.
- **$milestonesfile**: path to write or update. Default: `MILESTONES.md` at repo root.
- **$hints**: any remaining free-form text from the user (scope, constraints, focus area).
  Default: `(none)`.

State resolved values:
```text
$specpath:       <resolved value>
$milestonesfile: <resolved value>
$hints:          <resolved value, or "(none)">
```

## Important concepts

- **Component**: a self-contained unit of behavior with a clear input/output contract.
  Examples: a CLI subcommand, a backend trait impl, a persistence file format.
- **Subsystem**: a cluster of related components that together deliver a named capability.
  Examples: the GitHub backend, the state persistence layer, the branch resolution index.
- **Concern**: a single behavioral or architectural aspect addressed by a milestone.
  Examples: error handling on failure paths, making a naive impl production-safe,
  extracting a shared renderer.
- **Deliverable**: the observable outcome that makes a milestone verifiable.
  A deliverable is done when its Verification criteria can be executed and pass.

## Phases

1. `Phase:Discover` — read spec, identify capability boundaries.
2. `Phase:Draft` — sketch milestones by topic name.
3. `Phase:Discuss` — iterate, surface tradeoffs, identify parallel tracks.
4. `Phase:Finalize` — readiness check + fill in the blanks.

## 1. `Phase:Discover` — read spec, identify capability boundaries

When entering `Phase:Discover`: read <./refs/phases/discover.md> for full instructions.

Ready to move to `Phase:Draft`? (say 'next' or similar to proceed)

## 2. `Phase:Draft` — sketch milestones by topic name

When entering `Phase:Draft`: read <./refs/phases/draft.md> for full instructions.
The views are in <./refs/discussion-views.md>.

After the user confirms the draft shape:
read <./refs/file-format.md> and <./refs/file-draft-form.md> before the file-creation step.
**The written file is now the source of truth for the plan.**

Ready to move to `Phase:Discuss`? (say 'next' or similar to proceed)

## 3. `Phase:Discuss` — iterate, surface tradeoffs, identify parallel tracks

When entering `Phase:Discuss`: read <./refs/phases/discuss.md> for full instructions.

Ready to move to `Phase:Finalize`? (say 'next' or similar to proceed)

## 4. `Phase:Finalize` — readiness check + fill in the blanks

When entering `Phase:Finalize`: read <./refs/phases/finalize.md> for full instructions.
Read <./refs/file-final-form.md> to fill the final-form entries.

## Milestone ordering rules

- **M1 is always a research milestone** if any spec assumptions are unconfirmed.
  Output is written findings (e.g. in `findings/`), not production code.
  Investigates anything the spec marks as uncertain or "to be confirmed empirically".
  Research milestones are not limited to M1 — a later milestone may also be a research spike
  when a technical question blocks the next implementation step.
  Prefer to front-load research, but do not force it when the uncertainty only surfaces later.

- Each milestone builds on its dependencies.
  A milestone is not started until all its dependencies are verifiable.

- **Make-it-work → make-it-right → make-it-fast, in that order.**
  A naive or hardcoded implementation is a valid first milestone.
  A later milestone replaces it with better internal structure without changing observable output.
  Do not delay a working end-to-end slice waiting for the architecture to be right.

- **Each milestone addresses a single concern.**
  Do not mix make-it-work and make-it-safe/right concerns in the same milestone.
  Production-safety work (error paths, constraint enforcement) is its own milestone,
  placed after the happy-path milestone it extends.

- **Refactoring is scoped by size and placement.**
  A small or local refactor may be the first task of the milestone that requires it — it does not
  need its own milestone.
  A large refactor that touches multiple components or subsystems warrants its own milestone.
  When a refactor opens a milestone alongside new feature work, it must be the first task,
  and no other refactor may appear in the same milestone.
  A milestone that is *entirely* a refactor is unusual — flag it and ask user for confirmation.
  It often indicates accumulated technical debt from a poorly planned earlier sequence.

- **Shared components/subsystems that are large or multi-faceted must be explicit deliverables.**
  They need their own Goal and Proof criteria.
  They may span multiple milestones — started in one, refined in another, reused later.
  Small or simple shared components may remain implicit in the first milestone that introduces them.

- **Configuration and naming schemes that other components depend on must be explicit
  deliverables.**
  Do not silently assume a naming convention or config structure in a later milestone without
  a prior milestone that establishes and verifies it.

- **Persistence layer design must be explicit if the spec does not include it.**
  For a database: add a dedicated design milestone (with a PoC if the schema is uncertain).
  For a cache: a dedicated design milestone is optional; the first milestone that writes to it
  may establish the format, and a later "make it fast" milestone may refine it.
  Read and write operations should not be split by default — treat them together unless there
  is a concrete reason to separate.

- Milestones are thin vertical slices.
  A component or subsystem may appear across multiple milestones as it gains behaviors.
  The first milestone for a component delivers the minimal happy path.
  Do not wait for a subsystem to be complete before closing a milestone.

## Grouping heuristics

**Default: one concern per milestone.**
Bundling two or more concerns requires explicit justification or be required by user.
Never a silent default.

**When bundling may be justified**:
- Both concerns are small and tightly coupled (neither is verifiable without the other).
- The shared infrastructure between them is so thin that splitting would create a milestone
  with no standalone verifiable deliverable.

**When bundling is wrong**:
- One concern is significantly larger or more complex than the other.
- The concerns belong to different phases (e.g. happy path + production safety).
- Bundling hides a deliverable that future readers would need to understand the ordering.

**CI setup**:
Do not defer CI past the first milestone that produces testable, non-trivial output.
CI enables continuous regression detection at each increment — deferring it defeats the purpose
of incremental verification.

**Packaging and release tooling**:
Packaging (nix flake, homebrew formula, release pipeline, etc.) belongs near the end,
after the core feature set is stable.
Do not bundle packaging with an unrelated feature milestone.

## What belongs / does not belong

**Belongs in a milestone**:
- Functional behavior: what the user/system can do after this milestone.
- Observable outputs: CLI output, file artifacts, git state, exit codes.
- Constraints inherited from the spec (e.g. "never silently overwrites").
- A naming scheme or configuration format, when other components depend on it.
- A thin verification path even when no user-facing output exists yet.
  If a milestone delivers infrastructure with no CLI entry point, include a minimal stub command
  or test that exercises the layer end-to-end.
  The goal is that the milestone is independently verifiable without deferring to a later milestone.

**Does not belong in a milestone**:
- Implementation language choices, library names, internal architecture — unless they are
  behavioral constraints (e.g. "no `gh` CLI dependency" is behavioral).
- Speculative tasks or nice-to-haves not grounded in the spec.
- Step-by-step implementation instructions — those belong in individual task files.
