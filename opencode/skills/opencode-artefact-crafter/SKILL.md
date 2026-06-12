---
name: opencode-artefact-crafter
description: |
  Load when user asks to create, update, edit, or refactor any OpenCode (OC)
  artefact: skills, agents, commands, or snippets — including modifying an existing one.
  Triggers examples: "create skill to …", "draft a command to …", "add Y to OC cmd Z",
  "edit the W agent", "update crafter skill".
  Guides user through discovery, drafting, and iterative refinement.
---

# OpenCode Crafter

Design & create OpenCode artefacts: **skills**, **agents**, **commands**, **snippets**.

Work separated in phases:

1. `Phase:classify` — Identify right artefact type
2. `Phase:discover` — Gather requirements through focused questions
3. `Phase:draft` — Plan structure; setup `$draftpath`; Iterate on draft with user
3.5. `Phase:scripts` _(if needed)_ — POC & iterate on scripts via subagent
4. `Phase:review` — Review & refine with user via subagent
5. `Phase:ship` — Copy from `$draftpath` to `$installpath` (new artefacts only)

**For new artefact**:
classify → discover → draft → (scripts) → review → ship

**For updating existing artefact**:
classify → discover → draft → (scripts) → review

Three paths used throughout:
- `$draftpath` — where files are edited during crafting session.
- `$installpath` — final install location, inferred from artefact type & scope (project vs global).
- `$existingpath` — path where an existing artefact already lives (updates only).

At potential end of each phase, mention "Ready to move to <next-phase>? (say 'next' or similar to proceed)".
Informational only — do not use `question` tool for it.

NOTE: When skill invoked, must ask: "Retitle session to reflect artefact work?" — unless:
- Session is fresh (no prior context).
- Prior discussion is already about the artefact being worked on.

### Session titling

Session titling conventions (if retitle tool is available):
- Title format: `<phase>: <artefact-type>/<artefact-name> — <brief-what>`
  where `<brief-what>` is scope/goal (e.g. "new", "add retitle support", "rework discover phase")
  e.g. `classify: skill/my-skill — new`, `draft: snip/my-snippet — support X/Y`, `review: cmd/foo — rework args to …`
- At start of entering a phase — including re-entry (e.g. "start over", restart) — retitle with that phase name as prefix.
  Only retitle AFTER user confirms transition (e.g. said 'next', 'proceed', 'yes').
  Never retitle preemptively based on agent's own readiness signal.
- Keep `<brief-what>` stable across phase transitions.
  Only update if what's being built/changed shifts.
- When artefact is fully shipped (or update confirmed), retitle with prefix `done:`
  e.g. `done: skill/my-skill — add retitle support`

## 1. `Phase:classify` — Identify right artefact type

If target artefact already exists, treat as update:
- Use existing files as starting draft for `Phase:draft`, focusing only on requested changes.
- `$draftpath` = `$installpath` for updates — edit files in-place, no tmp copy needed.
- Still go through all remaining phases — including `Phase:review`.

If creating new artefact: read `./references/classify-new.md` for type decision rules & artefact-gate check.

Based on artefact type, read one of following references for full spec of that type:
- skill: `./references/skill-anatomy.md`
- command: `./references/command-anatomy.md`
- agent: `./references/agent-anatomy.md`
- snippet: load `snippets` skill for full spec

If skill will use a script, read `./references/skill-with-script.md`.

## 2. `Phase:discover` — Gather reqs through focused questions

Ask focused questions until you have enough requirements to draft.

For all artefact types:
- Single responsibility of artefact?
- Project-scoped or global/personal?
- Any constraints, failure modes, or edge cases?
  (may appear during review iterations or later as artefact used in different contexts)

For skills additionally:
- What inputs does agent receive? What should it produce?
- Any reference docs, scripts, or templates needed?
- Any sub-scenarios where only part of instructions applies?
  If yes: apply progressive disclosure — read `./references/skill-anatomy.md` § Progressive Disclosure
  for pattern (split criteria, conditional trigger syntax).

For agents additionally:
- Primary agent or subagent? Hidden from autocomplete? Isolated context?
- Which tools should be allowed, denied, or ask-before-use?
- Different model or temperature needed?

For commands additionally:
- What arguments does it take? (if any)
- Shell output or file content injection needed?
- Run in subagent session to avoid polluting context?

For snippets additionally:
- Trigger name? any aliases?
- Expand inline, or use `<append>`/`<prepend>` blocks?
- Shell command output injection needed (`` !`cmd` ``)?

## 3. `Phase:draft` — Plan structure; setup `$draftpath`; Iterate on draft

**First**: establish `$draftpath`.
- New artefact: use `/tmp/opencode_crafter/<type>-<name>/`.
- Update: `$draftpath` = `$existingpath` (path where artefact already lives) — no copy needed.

Write all draft files to `$draftpath` as soon as they exist.
**Writing files early is critical** — protects draft content from context compression in long sessions.
Keep updated after every meaningful change.

Do not output draft content inline. Tell user where to inspect it:
> Draft written to `$draftpath/<filename>` — open to inspect.

Note open questions & tradeoffs.

Basic writing style: lean & terse — imperative, no filler.
State intent & constraints only; do not prescribe output structure or section layout.
NOTE: Use `caveman` skill for drafting artefact files & all communication with user during crafting process.

Ask: *Does this match what you had in mind?*

Iterate until user explicitly confirms draft is ready.
Then proceed to `Phase:scripts` (for skill, if scripts needed) or `Phase:review`.

## 3.5. `Phase:scripts` (if needed) — Script POC & iterate via subagent

Skip phase if artefact does NOT have script.
If skill will use a script: read `./references/phase-scripts.md` for full instructions.

## 4. `Phase:review` — Review & iterate with user via subagent

When entering Phase:review: read `./references/phase-review.md` for full instructions.
After subagent returns & user confirms (update path): retitle session with `done:` prefix (see § Session titling).

## 5. `Phase:ship` — Write (new artefacts only)

Skip this phase for updates — `$draftpath` = `$installpath`, files are already in place.
When entering Phase:ship (new artefact only): read `./references/phase-ship.md` for full instructions.
After ship confirmed: retitle with `done:` prefix (see § Session titling).
