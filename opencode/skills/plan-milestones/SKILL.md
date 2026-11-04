---
name: plan-milestones
description: |
  Load when user asks to plan, create, or update project milestones.
  Examples: "plan milestones", "break this into milestones", "create MILESTONES.md",
  "write milestones for this spec", "add a milestone", "update milestones",
  "generate task files for the milestones", "define tasks for M3", "continue scoping tasks",
  "order more milestones", "promote backlog items".
  Also load on generic "plan work" phrasing.
metadata:
  maintainers: [bew]
---

## Goal

Produce a well-ordered `MILESTONES.md` where every milestone is a thin, independently verifiable
vertical slice, progressing make-it-work → make-it-right → make-it-fast.

## Setup — resolve inputs

Skip `Setup` when continuing an existing plan — read <./refs/continuing-a-plan.md> instead.

Determine the following from whatever is in context (user message, prior context, or defaults):
- **$specpath**: where the project spec lives (file path, directory, or glob).
  Required — stop and ask user if absent.
- **$milestonesfile**: path to write or update.
  Resolve placement:
  - `$milestonesfile` already exists → reuse it, no question.
  - `$specpath` is a single file at the repo root → `MILESTONES.md` at repo root, no question.
    Repo root = `git rev-parse --show-toplevel`.
  - Otherwise → ask user (use the `question` tool when available).
    Options (first recommended):
    - **Next to the spec** — `MILESTONES.md` in the spec's directory.
      Single file → its parent dir; directory → inside it; glob → common parent dir of matches.
    - **At repo root** — `MILESTONES.md` at the repo root.
    When repo root is unresolved (not a git repo), offer only **Next to the spec**;
    user may type a custom path.
- **$taskdir**: where scoped task files go.
  Always `dirname $milestonesfile` — next to the plan, no question.
- **$orderwindow**: how many milestones carry settled ordering.
  Default: `5`.
  Overridden by `$hints` or an explicit user request; "plan everything" → `all`.
  `Phase:Discuss` may adjust it when the user asks.
- **$hints**: any remaining free-form text from the user (scope, constraints, focus area).
  Default: `(none)`.

State resolved values:
```
$specpath:       <resolved value>
$milestonesfile: <resolved value>
$taskdir:        <resolved value>
$orderwindow:    <resolved value, or "all">
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
- **Scoped task**: a work unit with its own task file under `$taskdir` — ready to execute.
- **Rough task**: a work unit listed inline as an idea, not yet scoped into a file.
- **Ordering window**: the milestones whose order is settled — the next `$orderwindow` past the
  delivery edge. They carry numbers, dependency edges, and an Ordering reason.
  The delivery edge is the last delivered milestone; on a fresh plan it is the start.
  The ordering rules apply as milestones are ordered — a concern belonging far ahead stays a
  backlog topic until promoted.
- **Backlog**: topics planned but not yet ordered. Topic name and Goal only, no numbers or edges.
  A pinned entry carries a free-form `Pinned:` line recording an ordering constraint the user
  already knows. Promotion consumes the line: its content moves into the milestone's Ordering
  reason.

## Phases

1. `Phase:Discover` — read spec, identify capability boundaries.
2. `Phase:Draft` — sketch milestones by topic name.
3. `Phase:Discuss` — iterate, surface tradeoffs, find parallel tracks; settle the ordering window
   and the scoping boundary.
4. `Phase:Finalize` — readiness check, fill in the blanks, and scope boundary tasks into files.

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

## 3. `Phase:Discuss` — iterate, surface tradeoffs; settle window and boundary

When entering `Phase:Discuss`: read <./refs/phases/discuss.md> for full instructions.
`Phase:Discuss` settles the order of the ordering window only, and ends by confirming the scoping
boundary — which milestones get task files now.

Ready to move to `Phase:Finalize`? (say 'next' or similar to proceed)

## 4. `Phase:Finalize` — readiness check, fill blanks, scope boundary tasks into files

When entering `Phase:Finalize`: read <./refs/phases/finalize.md> for full instructions.
Read <./refs/file-final-form.md> to fill the final-form entries.

## Continuing an existing plan

When the user asks to continue a plan — promote backlog topics, or scope tasks for milestones
already ordered — read <./refs/continuing-a-plan.md> and follow it.
Examples: "order more milestones", "promote backlog items", "define tasks for M3".

## Milestone ordering rules

- **M1 is always a research milestone** if any spec assumptions are unconfirmed.
  - Output is written findings (e.g. in `findings/`), not production code.
  - It investigates whatever the spec marks uncertain or "to be confirmed empirically".
  - Later milestones may be research spikes too, when a question blocks the next step.
  - Prefer front-loading research; do not force it when uncertainty surfaces later.

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
  - Small or local: the first task of the milestone that requires it, no milestone of its own.
  - Large or multi-component: its own milestone.
  - Alongside feature work it must be the first task, and the only refactor in that milestone.
  - All-refactor milestone: unusual, flag it and ask — usually technical debt from a poorly
    planned earlier sequence.

- **Shared components/subsystems that are large or multi-faceted must be explicit deliverables.**
  They need their own Goal and Proof criteria.
  They may span multiple milestones — started in one, refined in another, reused later.
  Small or simple shared components may remain implicit in the first milestone that introduces them.

- **Configuration and naming schemes that other components depend on must be explicit
  deliverables.**
  Do not silently assume a naming convention or config structure in a later milestone without
  a prior milestone that establishes and verifies it.

- **Persistence layer design must be explicit if the spec does not include it.**
  - Database: a dedicated design milestone, with a PoC if the schema is uncertain.
  - Cache: design milestone optional — the first milestone that writes to it establishes the
    format, and a later "make it fast" milestone refines it.
  - Read and write together by default; separate them only for a concrete reason.

- Milestones are thin vertical slices.
  A component or subsystem may appear across multiple milestones as it gains behaviors.
  The first milestone for a component delivers the minimal happy path.
  Do not wait for a subsystem to be complete before closing a milestone.

## Grouping heuristics

### One concern per milestone

Bundling two or more concerns requires explicit justification, or the user requiring it.
Never a silent default.

### When bundling may be justified

- Both concerns are small and tightly coupled (neither is verifiable without the other).
- The shared infrastructure is so thin that splitting would create a milestone with no standalone
  verifiable deliverable.

### When bundling is wrong

- One concern is significantly larger or more complex than the other.
- The concerns belong to different phases (e.g. happy path + production safety).
- Bundling hides a deliverable that future readers would need to understand the ordering.

### Splitting a single topic across milestones

A topic is not automatically one milestone just because it was one draft topic name.
Check every topic for a natural split:
- Distinct make-it-work / make-it-right / make-it-fast phases.
- Part of the topic depends on something that lands in a later milestone.
- Core logic vs. UI: prove the core end-to-end headless, then add the UI on top.
  Useful when the core is the risky part and the UI is mechanical once it is proven.

When splitting is justified, the first milestone for the topic covers the minimal happy path.
Later ones add safety, refactors, or performance refinements without changing the behavior the
first one established.

### CI setup

Do not defer CI past the first milestone that produces testable, non-trivial output.
CI enables continuous regression detection at each increment — deferring it defeats the purpose
of incremental verification.

### Packaging and release tooling

Packaging (nix flake, homebrew formula, release pipeline, etc.) belongs near the end, after the
core feature set is stable.
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
