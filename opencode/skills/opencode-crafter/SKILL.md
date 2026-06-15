---
name: opencode-crafter
description: |
  Load when user asks to create, update, edit, or refactor any OpenCode (OC)
  artefact: skills, agents, commands, or snippets — including modifying an existing one.
  Triggers examples: "create skill to …", "draft a command to …", "add Y to OC cmd Z",
  "edit the W agent", "update crafter skill".
  Guides user through discovery, drafting, and iterative refinement.
---

# OpenCode Crafter

Design & create OpenCode artefacts: **skills**, **agents**, **commands**, **snippets**.

Phases:

1. `Phase:Classify` — Identify right artefact type
2. `Phase:Discover` — Gather requirements through focused questions
3. `Phase:Draft` — Plan structure; setup `$draftpath`; Iterate on draft with user
3.5. `Phase:Scripts` _(if needed)_ — POC & iterate on scripts via subagent
4. `Phase:Review` — Review & refine with user via subagent
5. `Phase:Ship` — Copy from `$draftpath` to `$installpath` (new artefacts only)

**For new artefact**:
`Phase:Classify` → `Phase:Discover` → `Phase:Draft` → (`Phase:Scripts`) → `Phase:Review` → `Phase:Ship`

**For updating existing artefact**:
`Phase:Classify` → `Phase:Discover` → `Phase:Draft` → (`Phase:Scripts`) → `Phase:Review`

Three paths used throughout:
- `$draftpath` — where files are edited during crafting session.
- `$installpath` — final install location, inferred from artefact type & scope (project vs global).
- `$existingpath` — path where an existing artefact already lives (updates only).

At potential end of each phase, mention: "Ready to move to `Phase:<next>`? (say 'next' or similar to proceed)".
Informational only — do not use `question` tool for it.

NOTE: When skill invoked, must ask: "Retitle session to reflect artefact work?" — unless:
- Session is fresh (no prior context).
- Prior discussion is already about the artefact being worked on.

## Session titling
<!-- §session-titling -->

Session titling conventions (if retitle tool is available):
- Title format: `<phase>: <artefact-type>/<artefact-name> — <brief-what>`
  where `<brief-what>` is scope/goal (e.g. "new", "add retitle support", "rework discover phase")
  e.g. `classify: skill/my-skill — new`, `draft: snip/my-snippet — support X/Y`, `review: cmd/foo — rework args to …`
- At start of entering a phase — including re-entry (e.g. "start over", restart) — retitle with that phase name as prefix.
  Only retitle AFTER user confirms transition (e.g. said 'next', 'proceed', 'yes').
  Never retitle preemptively based on agent's own readiness signal.
- Keep `<brief-what>` stable across phase transitions.
  Only update if what's being built/changed shifts.
- When artefact is fully shipped (or update confirmed by user), retitle with prefix `done:`
  e.g. `done: skill/my-skill — add retitle support`
  NOTE: "confirmed by user" means user explicitly said so (e.g. "looks good", "ship it", "done").
  Never retitle `done:` based on agent's own judgment that work is complete.

## 1. `Phase:Classify` — Identify right artefact type

If target artefact already exists, treat as update:
- Use existing files as starting draft for `Phase:Draft`, focusing only on requested changes.
- `$draftpath` = `$installpath` for updates — edit files in-place, no tmp copy needed.
- Still go through all remaining phases — including `Phase:Review`.

If creating new artefact: read <./refs/classify-new.md> for type decision rules & artefact-gate check.

Based on artefact type, read one of following references for full spec of that type:
- skill: <./refs/skills-related/anatomy.md>
- command: <./refs/command-anatomy.md>
- agent: <./refs/agent-anatomy.md>
- snippet: load `snippets` skill for full spec

Ready to move to `Phase:Discover`? (say 'next' or similar to proceed)

## 2. `Phase:Discover` — Gather reqs through focused questions

Read <./refs/discover-questions.md> for full question set.

Ready to move to `Phase:Draft`? (say 'next' or similar to proceed)

## 3. `Phase:Draft` — Plan structure; setup `$draftpath`; Iterate on draft

**First**: establish `$draftpath`.
- New artefact: use `/tmp/opencode_crafter/<type>-<name>/`.
- Update: `$draftpath` = `$existingpath` (path where artefact already lives) — no copy needed.

**For skills**: before writing frontmatter, detect current user: `git config github.user || echo "no user found"`
- New skill: add `metadata.maintainers: [$currentuser]` to frontmatter.
- Update existing skill: if `maintainers` already present but does not include `$currentuser`, ask user whether to add `$currentuser` to the list.

Before writing any artefact prose: read <./refs/rules-for-writing.md> and <./refs/rules-for-steps-phases-headers.md>.
If skill includes a script: read <./refs/skills-related/with-script.md>.

Write all draft files to `$draftpath` as soon as they exist.
**Writing files early is critical** — protects draft content from context compression in long sessions.
Keep updated after every meaningful change.

Do not output draft content inline. Tell user where to inspect it:
> Draft written to `$draftpath/<filename>` — open to inspect.

Note open questions & tradeoffs.

Ask: *Does this match what you had in mind?*

Iterate until user explicitly confirms draft is ready.
Then proceed to `Phase:Scripts` (for skill, if scripts needed) or `Phase:Review`.

## 3.5. `Phase:Scripts` (if needed) — Script POC & iterate via subagent

Skip if artefact does not include a script (only skills support companion scripts).
If skill includes a script: read <./refs/phases/scripts.md> for full instructions.

## 4. `Phase:Review` — Review & iterate with user via subagent

When entering `Phase:Review`: read <./refs/phases/review.md> for full instructions.
After subagent returns & user confirms (update path): retitle session with `done:` prefix (see `§session-titling`).

## 5. `Phase:Ship` — Write (new artefacts only)

Skip this phase for updates — `$draftpath` = `$installpath`, files are already in place.
When entering `Phase:Ship` (new artefact only): read <./refs/phases/ship.md> for full instructions.
After ship confirmed: retitle with `done:` prefix (see `§session-titling`).
