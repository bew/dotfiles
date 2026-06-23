# [DRAFT] Complex Skills Rework 'v2' — Orchestrator-managed Phases & Context Handoffs

## Introduction

`opencode-crafter` has grown monolithic: long SKILL.md, deeply nested refs, phase logic tangled with artefact-type logic.
`write-spec` shares structural patterns (phased workflow, user iteration, review subagent) but cannot reuse any of it.
Token cost between phases is high — context re-emitted verbatim on each subagent launch.

This spec prepares a v2 of both skills under a new architecture:
- Thin orchestrators (SKILL.md owns only phase sequencing, no inline phase logic)
- All phases run as isolated subagents with fresh context
- File-based context handoffs between phases (no inline prompt re-emission)
- Shared primitives (subagents, ref files) reusable across both skills and future phased skills

Scope: analysis + design only — not implementation.
v2 will be written as new skills, not edits to existing ones.

## Terminology

**Orchestrator** (new!): the SKILL.md entry point loaded in the user's main session.
Owns phase sequencing: coordinates handoff files, launches subagents, waits for their return.
Does not perform the iterative work of any phase itself.
In v2, orchestrators are thin — no inline phase instructions, only sequencing logic.

**Subagent** (new!): agent launched via `task` tool to handle a bounded phase of work.
Receives handoff file paths at startup; has no access to the orchestrator's prior conversation.

**Context handoff file** (new!): structured file passed to a subagent at launch.
Written by the previous phase subagent (not the orchestrator).
Contains goal, refs, focus areas, open items from prior phase.
Orchestrator may review or edit between phases but does not author from scratch.

**Shared primitive** (new!): skill or agent not owned by any single orchestrator.
Reusable across `opencode-crafter`, `write-spec`, or any future phased skill.

**Topic log** (new!): orchestrator-maintained structured record of topics/concepts encountered across all phases.
Each entry has a status: `covered`, `wip`, `to-discover`.
Purpose: new-scope detection, phase re-entry resume, orchestrator routing decisions.
Written by orchestrator (from phase handoffs); read by subagents at startup to avoid re-covering or conflicting with prior work.

**Phase** (well-known): named stage in a skill's workflow with a defined entry trigger and exit gate.

**Isolated phase** (new!): phase executed by a subagent in a fresh context, receiving handoff files instead of sharing the orchestrator's conversation history.
v2 uses isolated phases for all phases.

**Ref file** (well-known): file in `refs/` read on demand by an agent; loaded only when its trigger condition is met.

**Vars** (new!): key/value pairs defined by the orchestrator at runtime (e.g. `$draftpath`, `$slug`).
Passed to subagents via the global context file.
Ref files and agent prompts reference them symbolically — never hardcoded.
Each skill defines its own path var names to reflect content (`$draftpath` vs. `$specpath`) — no cross-skill standardization.

## Component Inventory

### opencode-crafter

#### Phases

| Phase | Location | Description |
|---|---|---|
| `Phase:Classify` | SKILL.md (inline) | Identify artefact type; load anatomy ref; gate for new vs. update |
| `Phase:Discover` | SKILL.md (inline) + `refs/discover-questions.md` | Gather requirements via focused questions |
| `Phase:Draft` | SKILL.md (inline) | Set `$draftpath`; write files; iterate until user confirms |
| `Phase:Scripts` | `refs/phases/scripts.md` | POC & iterate on scripts via `opencode-skill-script-crafter` subagent |
| `Phase:Review` | `refs/phases/review.md` | Review & refine via `opencode-reviewer` subagent |
| `Phase:Ship` | `refs/phases/ship.md` | Copy from `$draftpath` to `$installpath` (new artefacts only) |

#### Subagents launched

| Subagent | Phase | Purpose |
|---|---|---|
| `opencode-skill-script-crafter` | `Phase:Scripts` | Write & iterate on companion scripts |
| `opencode-reviewer` | `Phase:Review` | Review artefact conformance; iterate with user |

#### Ref files

| File | Trigger condition |
|---|---|
| `refs/classify-new.md` | New artefact: type decision rules & artefact gate |
| `refs/skills-related/anatomy.md` | Artefact type = skill |
| `refs/agent-anatomy.md` | Artefact type = agent |
| `refs/command-anatomy.md` | Artefact type = command |
| `refs/tool-anatomy.md` | Artefact type = tool |
| `refs/plugin-anatomy.md` | Artefact type = plugin |
| `refs/skills-related/skill-phases.md` | Skill has/needs phases |
| `refs/skills-related/with-script.md` | Skill includes a companion script |
| `refs/rules-for-writing.md` | Before writing any artefact prose |
| `refs/rules-for-steps-phases-headers.md` | Before writing any artefact prose |
| `refs/discover-questions.md` | `Phase:Discover` entry |
| `refs/phases/scripts.md` | `Phase:Scripts` entry |
| `refs/phases/review.md` | `Phase:Review` entry |
| `refs/phases/ship.md` | `Phase:Ship` entry |

### write-spec

#### Phases

| Phase | Location | Description |
|---|---|---|
| `Phase:Discover` | `refs/phases/discover.md` | Gather name, slug, problem, inspirations; derive `$specpath` |
| `Phase:Draft` | `refs/phases/draft.md` | Write skeleton; fill sections top-to-bottom via `edit` |
| `Phase:Review` | `refs/phases/review.md` | In-context review pass; assess readiness; offer promotion |

#### Subagents launched

None. `Phase:Review` is in-context (same session), not delegated to a subagent.

#### Ref files

| File | Trigger condition |
|---|---|
| `refs/phases/discover.md` | `Phase:Discover` entry |
| `refs/phases/draft.md` | `Phase:Draft` entry |
| `refs/phases/review.md` | `Phase:Review` entry |
| `refs/spec-structure.md` | `Phase:Draft` — read for section order, prose rules |
| `refs/spec-readiness.md` | `Phase:Review` — readiness criteria |
| `refs/rename.md` | When spec name/slug needs to change |

### Ecosystem (dependencies of opencode-crafter)

These components are not orchestrators themselves, but are launched or loaded by `opencode-crafter`
during its phases. They are in scope for generalization analysis.

| Component | Type | Launched by | v2 fate |
|---|---|---|---|
| `opencode-reviewer` | agent | `Phase:Review` | Replaced by generic `reviewer` agent |
| `opencode-artefact-rules` | skill | loaded by `opencode-reviewer` | Absorbed into crafter as ref files; reviewer becomes rule-agnostic |
| `opencode-test-runner` | skill | loaded by `opencode-reviewer` in `Phase:Testing` | Promoted to standalone primitive; loaded directly by new `Phase:Test` in crafter |
| `opencode-skill-script-crafter` | agent | `Phase:Scripts` | Kept bespoke (domain too specialized to generalize) |

Notes:
- `opencode-reviewer`'s core loop (evaluate → fix autonomously → surface gaps → user loop) is already
  generic. The v1 specialization was in rule loading (`opencode-artefact-rules`). In v2, rules come
  from the handoff file — the reviewer itself becomes rule-agnostic.
- `opencode-artefact-rules` type-specific criteria (`refs/skills.md`, `refs/agents.md`, `refs/commands.md`)
  move to crafter as conditional ref files, loaded by the orchestrator before launching the reviewer.
  The skill wrapper is no longer needed.
- `opencode-test-runner` has no type coupling — pure dry-run simulation.
  In v2 it is promoted from a reviewer sub-step to a first-class `Phase:Test` in the crafter orchestrator.
  Testing is separated from review: reviewer no longer owns it.
- `opencode-skill-script-crafter` is bespoke: script writing + bats execution cannot be meaningfully
  generalized via a shared primitive without losing its domain specificity.

## Non-Goals

NOTE: This section captures what v2 explicitly does NOT address — add to as design evolves.

- Editing or refactoring existing v1 skills (`opencode-crafter`, `write-spec`) — v2 is written from scratch.
- Unifying path var naming across skills (each skill keeps its own `$draftpath` / `$specpath`).
- A handoff-reviewer agent — deferred unless handoff quality failures observed in practice.

## Redundancy Analysis

### Phase structure

Both skills share the same 3-phase backbone: Discover → Draft → Review.
crafter wraps it with artefact-specific bookends (Classify before, Scripts + Ship after).

| Concern | opencode-crafter | write-spec | Overlap? |
|---|---|---|---|
| Gather inputs | `Phase:Discover` | `Phase:Discover` | Yes — same intent, different questions |
| Write/iterate draft | `Phase:Draft` | `Phase:Draft` | Yes — same pattern, different content type |
| Review with user | `Phase:Review` | `Phase:Review` | Partial — same goal, different mechanism (see below) |
| Artefact type selection | `Phase:Classify` | — | crafter-only |
| Script iteration | `Phase:Scripts` | — | crafter-only |
| Install output | `Phase:Ship` | — | crafter-only |
| Spec promotion | — | inside `Phase:Review` | write-spec-only |

### Review mechanism divergence

crafter delegates review to `opencode-reviewer` subagent (separate context, task tool).
write-spec does review in-context (same session, no subagent).
Same user-facing goal — iterate until confirmed — but different execution model.
This divergence is the primary candidate for unification via a shared subagent.

### Phase gate pattern

Both skills end each phase with the same informational gate:

> Ready to move to `Phase:X`? (say 'next' or similar to proceed)

Identical wording, identical rules (no `question` tool, wait for user signal).
Currently duplicated in each skill independently.

### Writing rules

crafter has explicit writing rules in two ref files (`rules-for-writing.md`, `rules-for-steps-phases-headers.md`).
write-spec embeds its prose rules inline in `refs/spec-structure.md` and `refs/phases/draft.md`.
Both cover: tone, formatting, sentence-per-line, callout syntax, phase naming.
Significant overlap in intent; different levels of detail and surface area.

### Step/phase naming rules duplication

crafter's `refs/rules-for-steps-phases-headers.md` defines named step/phase syntax.
`opencode-artefact-rules/refs/skills.md` (criterion #2) and `refs/agents.md` (criterion #5) repeat
the same rules inline.

In v2, `opencode-artefact-rules` is absorbed into crafter as ref files.
The step/phase naming rules should exist in one canonical file (crafter-owned), referenced by all
type-specific criteria files — no duplication.

### Session titling

crafter has detailed session titling conventions (§session-titling section in SKILL.md).
write-spec has none — retitling is ad-hoc.
Not a candidate for extraction (crafter's convention is artefact-workflow-specific).

### Subagent launch pattern

crafter launches subagents by passing paths + inline instructions in the task prompt.
The orchestrator re-emits context each time (draft path, rule file paths, focus areas).
write-spec has no subagents — no handoff mechanism at all.
Neither skill uses a file-based context handoff today.

## Extraction Candidates

### Overview

| Candidate | Artefact type | Used by | Status |
|---|---|---|---|
| `iterate-with-user` | agent | Discover + Draft phases of all orchestrators | Confirmed |
| `reviewer` | agent | Review phase of all orchestrators | Confirmed — new v2 artefact replacing `opencode-reviewer` |
| `discover` subagent | agent | Replaced by `iterate-with-user` with questions file as input | Merged into iterate-with-user |
| Handoff file schema | ref file | All orchestrators, all subagents | Confirmed |
| `handoff-writer` | skill | Loaded by phase subagent (on orchestrator's instruction) to write outbound handoff | Confirmed (reviewer deferred) |
| Phase gate convention | ref file / note | All phases in all orchestrators | Trivial — folded into handoff schema |
| `opencode-test-runner` | skill | `Phase:Test` (new crafter phase); no longer owned by reviewer | Promoted — standalone primitive, loaded directly by orchestrator |

### `iterate-with-user` — Socratic loop agent

Interaction model: **Socratic**.
Asks questions to shape intent, fill gaps, confirm direction.
Does not enforce rules or apply fixes.
Output is a rough draft, a set of decisions, or a partially filled structure — not a final artefact.

Used for: `Phase:Discover` and `Phase:Draft` in both crafter and write-spec v2.
Both phases are about understanding and shaping intent — the difference is the questions file and rule refs passed via handoff.

Draft phase may pass more structure/rules than Discover, but less than Reviewer.
The handoff file's `rules:` field controls this — same agent, different inputs.

NOTE: relationship to `reviewer` (specialization vs. sibling) is unresolved — see Open Questions.

### `reviewer` — Editorial enforcement agent

Interaction model: **Editorial**.
Receives an existing draft + rule refs.
Applies fixes directly for anything it can resolve autonomously.
Surfaces only what it cannot fix: genuine ambiguities, gaps requiring user decisions, unresolved tradeoffs.
Output is a finished, conformant artefact.

Runs in **isolated context**: no access to prior session conversation.
All needed context must be in the handoff file (draft path, rule refs, focus areas, vars).

Used for: `Phase:Review` in both crafter and write-spec v2.
v2 `reviewer` replaces `opencode-reviewer` — same role, generalized to work across all orchestrators, not just crafter.

Can ask questions along the way — but only for things it cannot resolve from the draft + rules alone.

NOTE: whether `reviewer` is a specialization of `iterate-with-user` is unresolved — see Open Questions.

### `handoff-writer` skill

Orchestrator instructs each phase subagent to load `handoff-writer` and write its outbound handoff to `$handoff` (a phase-specific path).
The skill provides: required fields checklist, format rules, what must never be omitted.
Ensures handoff quality is owned by the agent with the most context (the one that just ran the phase).

Rationale for skill (not agent): composable, zero extra round-trip, no review overhead.
A dedicated handoff-reviewer agent would add overhead per phase transition — defer unless quality failures observed in practice.

### `opencode-test-runner` — dry-run testing primitive

Runs structured simulation tests against a draft artefact: generate test cases, narrate dry-runs, report pass/fail.
No artefact-type coupling — purely process-driven.

In v1, it is a sub-step inside `opencode-reviewer`'s `Phase:Testing`.
In v2, testing is separated from review: `opencode-test-runner` becomes a standalone primitive
loaded directly by a new `Phase:Test` in the crafter orchestrator.

Write-spec v2 may adopt `Phase:Test` as well — dry-run testing of a spec section structure is plausible.

OQ on execution model (dry-run only vs. real execution) — see Open Questions.

### Phase isolation model

All phases in v2 run as isolated subagents.
Orchestrator is thin: only sequences phases, coordinates handoff files, launches subagents.
No inline phase instructions in SKILL.md body.

Benefit: each phase starts with a clean context — no token bleed from prior phases.
Cost: handoff file quality is critical; anything not captured is lost.
The `handoff-writer` skill is the mitigation for this cost.

### Phase navigation

Orchestrator is not a strict linear pipeline.
It can navigate back to a prior phase when more discovery or drafting is needed
(e.g. review surfaces a gap that requires revisiting Discover).
Handoff files are not unique per phase — they can be rewritten on re-entry.

### Phase early exit

A phase subagent may need to terminate before completing its normal work.

Trigger: mid-phase signal that cannot be handled within the current phase.
Example: user introduces new scope during `Phase:Draft` — subagent detects it, asks user,
user confirms the new scope needs a Discover loop first.

In this case the subagent must:
1. Ask user to confirm early exit.
2. Write its outbound handoff with `exit_reason` set (e.g. `new_scope`, `blocker`, `user_abort`).
3. Capture any partial work completed so far (so re-entry doesn't start from zero).
4. Terminate. The orchestrator reads `exit_reason` and decides routing (e.g. back to Discover, then re-enter Draft).

This pattern also covers: unresolvable blockers, user-requested pauses, and any other reason
a phase cannot proceed to its normal completion.

Common triggers and expected orchestrator response:

| `exit_reason` | Example trigger | Orchestrator action |
|---|---|---|
| `new_scope` | Mid-feedback: *"actually, what if we also supported dark mode?"* | Re-run Discover for new scope, then re-enter Draft |
| `constraint_conflict` | *"wait, make it read-only — nothing should mutate it"* — contradicts a prior decision | Re-run Discover with revised constraint, then re-enter Draft |
| `user_abort` | *"hold on, I need to check how the auth layer works first"* | Hold; re-enter current phase when user resumes |
| `blocker` | Subagent hit gap it cannot resolve from available context | Surface to orchestrator; orchestrator decides routing |

NOTE: `exit_reason` is a required field in the phase handoff schema (see Context Handoff Design).
The `handoff-writer` skill must enforce its presence when the subagent exits early.

IMPORTANT: This is a **BLOCKING** design question — see Open Questions.

### Open Questions — Extraction Candidates

1. Is `reviewer` a specialization of `iterate-with-user`, or a sibling sharing only a protocol?
   Non-blocking. Interaction models differ enough that forcing a hierarchy may distort both.
   Resolve during v2 design of the two agents — if they share no code/rules, treat as siblings.

2. Does `iterate-with-user` need a "done" detection mechanism, or does it always rely on explicit user signal?
   Non-blocking. Explicit signal (phase gate) is the current model — changing it has broader implications.

3. Should `Phase:Discover` output include a Non-Goals section to surface what the user does NOT want built?
   Non-blocking. Would prevent scope creep early; adds a standard field to the discover handoff output.

4. Should `Phase:Test` run dry-run simulation only (`opencode-test-runner` as-is), or also support real
   execution (e.g. bats tests for artefacts that have scripts)?
   Non-blocking. Real execution may require integration with `Phase:Scripts` output.

5. **BLOCKING** — Phase early exit protocol: how does a subagent signal early exit to the orchestrator,
   and what is the full contract (handoff fields, orchestrator re-routing rules, partial work preservation)?
   Blocks `handoff-writer` skill design and `iterate-with-user` agent design.
   The `exit_reason` field in the handoff schema is a placeholder — the full protocol is unresolved.

6. How is partial work from an early-exit phase preserved and resumed when the phase is re-entered
   with potentially new or conflicting context (e.g. new scope from Discover, reversed constraint)?
   Non-blocking but coupled to OQ 5.
   Options: overwrite handoff on re-entry (simple, loses partial work), keep prior handoff as a
   separate snapshot (auditable, more complex), or merge partial work into the new Discover output
   before Draft resumes (needs a merge protocol).

## Context Handoff Design

NOTE: This section is a rough draft — schema and ownership model are not finalized.
Treat as a starting point for v2 design, not a binding spec.

### Purpose

Subagents in v2 run in isolated context.
They receive one or more handoff files at startup — no dependency on orchestrator's in-context state.
Replaces the current model of passing inline verbose prompts to `task` tool.

### Handoff file ownership

Each phase subagent writes its own outbound handoff file at the end of its work.
The orchestrator directs the subagent to do so (via the task prompt or input handoff) and may review/edit the result.
The orchestrator does not author handoff files from scratch — it stays thin.
Handoff quality is owned by the agent that has the most context (the one that just ran the phase).

On phase re-entry (navigation back), the existing handoff file for that phase is updated in-place.

### Multi-level handoffs

A subagent may receive multiple handoff files, not just one:

- **Global context file**: maintained by the orchestrator across the full session.
  Contains vars, session-level state, and cross-phase facts that every phase needs.
  Written/updated by the orchestrator when session-level state changes.

- **Phase-specific handoff file**: written by the previous phase subagent.
  Contains phase output, focus areas, open items, and anything the next phase must know.

Subagent startup: read global context file first, then phase-specific handoff.
Phase-specific content overrides global defaults where they conflict.

### Rough schema (global context file)

```md
# Session Context

## Vars
- `$<skill-specific-path-var>` = <absolute path to primary output>
- `$slug` = <identifier>
- <other session-level vars>

## Session state
<facts established so far: decisions made, constraints discovered>
```

### Rough schema (phase handoff file)

```md
# Handoff: <PhaseName>

## Exit status
exit_reason: <normal | new_scope | blocker | user_abort>
# Required. "normal" = phase completed. Anything else = early exit; orchestrator must re-route.

## Goal
<one sentence: what the next phase subagent must produce>
# Omit if exit_reason != normal.

## Refs
- <absolute path to rule file>: <one-line purpose>

## Focus areas
<specific aspects, known gaps, tricky areas>

## Open items
<decisions deferred, unresolved questions carried forward>

## Partial work
<only present on early exit: what was completed, what was not, where to resume>
```

### Topic log

The orchestrator maintains a structured log of topics/concepts encountered across phases.

Each entry:

```md
- `<topic>`: <covered | wip | to-discover>
```

Purpose:
- **New-scope detection**: subagent checks log at startup; if a user idea matches a `covered` entry, it's known context, not new scope; if absent, it's a candidate for early exit
- **Phase re-entry**: on re-entering a phase after early exit, subagent knows exactly what was done and what wasn't
- **Orchestrator routing**: orchestrator uses log state to decide which phase to re-enter after a `constraint_conflict` or `new_scope` exit

The log is written by the orchestrator, sourced from topics mentioned in phase handoff files.

OQ: see Open Questions — boundary with global context file's session state, and orchestrator pollution risk.

### Vars

Vars are defined in the global context file and passed to every subagent.
Subagents reference them symbolically — never hardcode paths inline.
Each skill uses its own path var names (e.g. `$draftpath`, `$specpath`) — no cross-skill standardization.

### `handoff-writer` skill integration

Loaded by phase subagent (on orchestrator's instruction) before writing outbound handoff.
Provides: required fields checklist, what to capture from current phase output, format rules.

### Open Questions — Context Handoff Design

1. Where do handoff files live? Inside `$draftpath`/`$specdir`, or in a dedicated scratch dir?
   Non-blocking. Decide before writing `handoff-writer` skill.

2. Handoff file naming convention: `handoff-<phase>.md` vs. `<phase>-context.md` vs. something else?
   Non-blocking. Decide before writing `handoff-writer` skill.

3. Should handoff files be committed to the repo (for auditability) or treated as ephemeral scratch?
   Non-blocking. Ephemeral is simpler; committed is useful for debugging failed phases.

4. Is the global context file always present, or only when a skill has 3+ phases?
   Non-blocking. May be overkill for short skills.

5. Can a phase subagent update the global context file, or only the orchestrator?
   Non-blocking. Allowing subagents to update it risks conflicts; restricting it puts burden on orchestrator.

6. Where do phase subagent definitions live, and how are they given to the agent?
   Blocking for v2 implementation. Each orchestrator skill likely defines its phase agents in a separate file
   (e.g. `refs/agents/<phase>.md`), passed via the task prompt — but this is unresolved.

7. Is the topic log the same thing as the global context file's `## Session state` section (better structured),
   or a separate file with its own lifecycle?
   Non-blocking. Boundary between log (structured, per-topic) and session state (prose, per-decision) is unclear.

8. **BLOCKING** (coupled to OQ 5 in Extraction Candidates) — Orchestrator context pollution:
   if the orchestrator reads every phase handoff to update the topic log, it accumulates context
   across phases — contradicting the thin-orchestrator goal.
   Who maintains the log, when, and how is the orchestrator shielded from full handoff content?
   Options:
   - `handoff-writer` extracts and appends topics at phase end (orchestrator never reads handoffs)
   - orchestrator reads lazily only on routing decisions
   - dedicated log-updater subagent
   - ..?

## Alternatives & Tradeoffs

### Isolated phases vs. inline phases

**Inline phases** (current model): phase instructions live in orchestrator's session context.
All phases share conversation history — user nuances from Discover are naturally available in Draft.

Advantages of inline:
- No handoff file required
- User nuances propagate automatically
- Simpler orchestrator

Advantages of isolated phases (v2 model):
- Each phase starts with clean context — no token bleed
- Phase agents are independently testable and reusable
- Orchestrator stays thin; skill SKILL.md stays short

Cost of isolated phases:
- Handoff file quality is critical — anything not captured is lost
- Requires `handoff-writer` skill discipline per phase transition
- More moving parts: orchestrator + N subagents instead of one monolithic skill

**Heuristic**: use isolated phases when context bleed between phases is more harmful than the handoff overhead.
For long multi-phase sessions (crafter, write-spec), isolated phases win.
For short 2-phase skills, inline is sufficient.

### Inline verbose prompt vs. handoff file

**Inline prompt**: orchestrator passes all context as a string to `task` tool.
Simple, no extra files, works today.
Costs: re-emits tokens on every subagent launch; inconsistent structure; hard to review.

**Handoff file**: orchestrator writes structured file; subagent reads it.
Costs: extra write step; requires `handoff-writer` discipline.
Benefits: stable schema, reviewable, reusable across subagent restarts, zero token re-emission.

### Open Questions — Alternatives & Tradeoffs

1. Where do shared primitives live? Global `~/.config/opencode/agents/` or per-skill `refs/`?
   Blocking for v2 implementation. Affects install path conventions and how subagents reference shared ref files.

