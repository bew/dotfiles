# Handoff: Skill Trigger & Input Extraction Pattern

## Introduction

This document captures all work done across two sessions on formalising how skills handle
their own trigger conditions and structured input extraction.

The root insight is: a skill may be invoked by a command, by another skill, or directly by the
user — and any extraction logic that lives in a command is invisible to the other two paths.
This means skills must own their own input extraction, and commands must stay as thin launchers.

A second insight emerged from the diff-to-commits-drafts friction session: the `description`
frontmatter field is the only signal the agent uses to decide whether to load a skill.
It must encode the trigger condition precisely, and include concrete examples of when to load,
because new cases are discovered only as the skill is used in real situations.

The following new reference files were written and integrated into the crafter skill:

- `refs/skills-related/with-command-trigger.md` — ownership rule, thin launcher template, no-arguments variant
- `refs/with-precise-inputs.md` — `## Setup` section pattern, rules for required vs defaulted inputs (shared between skills and agents)
- `refs/skills-related/trigger-styles.md` — taxonomy of 10 trigger styles with actual trigger text examples

And the following files were updated to point to these new refs:

- `refs/skills-related/anatomy.md` — trigger style section moved next to Frontmatter; Structured inputs note added
- `refs/agent-anatomy.md` — Structured inputs cross-reference added after Body section
- `refs/discover-questions.md` — trigger style + structured inputs questions added for skills
- `opencode-artefact-rules/refs/skills.md` — old criterion 8 split into Trigger style (8) + Structured inputs (9); Flow correctness renumbered to 10
- `opencode-artefact-rules/refs/commands.md` — criterion 5 added: thin launcher check

Additionally, the following real artefacts were updated to conform to the new patterns:

- `commands/diff-to-commits-drafts.md` → thin launcher
- `skills/diff-to-commits-drafts/SKILL.md` → `## Setup` section added
- `commands/draft-commit-message.md` → thin launcher
- `skills/draft-commit-message/SKILL.md` → `## Setup` section added

## Terminology

- **Thin launcher** (new!): a command whose body contains no extraction or interpretation of `$ARGUMENTS`.
  It surfaces user context verbatim and delegates everything to the skill.
- **Trigger style** (new!): the condition that causes a skill to load, as encoded in the `description` field.
- **`## Setup` section** (new!): the first section of a skill or agent body that extracts and resolves structured inputs from context, with no assumption about the caller.
- **Ownership rule** (new!): the invariant that a skill owns extraction of its own inputs, not the command that triggered it.

## Remaining Work

### Review not completed

The `opencode-reviewer` subagent was NOT run on the final batch of files from the second session.
Files that need review:

- `refs/skills-related/with-command-trigger.md`
- `refs/with-precise-inputs.md`
- `refs/skills-related/trigger-styles.md`
- `refs/skills-related/anatomy.md`
- `refs/agent-anatomy.md`
- `refs/discover-questions.md`
- `opencode-artefact-rules/refs/skills.md`
- `opencode-artefact-rules/refs/commands.md`

### Open Questions

1. ~~**`with-precise-inputs.md` scope**: moved to `refs/with-precise-inputs.md` (shared between skills and agents). All references updated. Resolved.~~

2. **Command thin launcher: working directory injection**: the command does NOT inject working directory
   (no shell injection in thin launcher template).
   The skill infers it from the session prompt.
   This was decided for diff-to-commits-drafts and draft-commit-message, but not codified as a rule
   in `with-command-trigger.md`.
   Non-blocking. Could be a note in the file.

3. ~~**`with-command-trigger.md` template form (thin launcher)**: done — `diff-to-commits-drafts` and
   `draft-commit-message` commands were converted to thin launchers.~~
   **Remaining**: both commands still use the old inline `User context: \`$ARGUMENTS\`` style,
   not the new fenced-block template from `with-command-trigger.md`.
   Blocking if consistency matters. Those commands need a follow-up edit pass.

4. **`discover-questions.md` update scope**: the session summary says questions were added between
   "What inputs" and "Any reference docs" for skills.
   No equivalent was added for agents.
   Non-blocking. Agent discovery questions are less structured currently.

5. **Trigger style examples in `trigger-styles.md`**: examples are now actual description text quoted
   from existing skills.
   When those skills' descriptions change, the examples become stale.
   Non-blocking. Stale examples are still illustrative; this is a maintenance burden, not a bug.

6. ~~**`opencode-crafter` own description**: the crafter skill description was extended mid-session
   to also trigger on direct file edits targeting OC artefact files.
   This was reviewed by `opencode-reviewer` in the first session. Resolved.~~

## Alternatives & Tradeoffs

### Extraction in command vs. skill

The rejected alternative was keeping extraction in the command (parsing `$ARGUMENTS` into named
values before loading the skill).
Tradeoff: simpler command body, but extraction is invisible to direct skill loads.
Decision: skill owns extraction; command is a thin launcher.
This matches how agents work — a subagent prompt may provide structured context, but the agent
body must handle the case where it doesn't.

### Single file (`with-trigger-and-inputs.md`) vs. split

The original single file was split into `with-command-trigger.md` and `with-precise-inputs.md`
because the two concerns are orthogonal: a skill may have a command trigger without structured
inputs, and vice versa.
Decision: split by concern, cross-reference each other.

### `with-precise-inputs.md` scope: skills only vs. skills + agents

Initially written as skills-only.
Updated to cover both skills and agents because agents face the same structured-input problem
(e.g. a subagent prompt may or may not contain the expected inputs).
Decision: generalise; moved to `refs/` (shared). See resolved Open Question 1.
