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

Helps users design & create OpenCode artefacts: **skills**, **agents**, **commands**, **snippets**.

Work in multiple phases:

1. `Phase:classify` — Identify right artefact type
2. `Phase:discover` — Gather requirements through focused questions
3. `Phase:draft` — Plan structure; setup `$draftpath`; Iterate on draft
3.5. `Phase:scripts` _(if needed)_ — POC & iterate on scripts via subagent
4. `Phase:review` — Review & refine with user via subagent
5. `Phase:ship` — Copy from `$draftpath` to `$installpath` (new artefacts only)

Two paths used throughout:
- `$draftpath` — where files are edited during crafting session.
- `$installpath` — final install location, inferred from artefact type & scope (project vs global).

At potential end of each phase, mention "Ready to move to <next-phase>? (say 'next' or similar to proceed)".
This is informational only — do not use `question` tool for it.

NOTE: When skill invoked, if there is prior conversation context on a different topic, ask user if they want to retitle session to reflect artefact work.
- Skip if session is fresh.
- Skip if prior discussion is already about artefact being worked on.

### Session titling

Session titling conventions (if a retitle tool is available):
- Title format: `<phase>: <artefact-type>/<artefact-name> — <brief-what>`
  where `<brief-what>` is scope/goal (e.g. "new", "add retitle support", "rework discover phase")
  e.g. `classify: skill/my-skill — new`, `draft: snip/my-snippet — support X/Y`, `review: cmd/foo — rework args to …`
- At start of entering a phase — including re-entry (e.g. "start over", restart) — retitle with that phase name as prefix.
  Only retitle AFTER user has confirmed transition (e.g. said 'next', 'proceed', 'yes').
  Never retitle preemptively based on agent's own readiness signal.
- Keep `<brief-what>` stable across phase transitions.
  Only update if what's being built or changed shifts.
- When artefact is fully shipped (or update confirmed), retitle with prefix `done:`
  e.g. `done: skill/my-skill — add retitle support`

## 1. `Phase:classify` — Identify right artefact type

NOTE: If target artefact already exists, treat this as an update.
Use existing files as starting draft for `Phase:draft`, focusing only on requested changes.
`$draftpath` = `$installpath` for updates — edit files in-place, no tmp copy needed.
Still go through all remaining phases — including `Phase:review`.

Ask user what they want to create if not already clear.
Use decision table below to confirm right artefact type.

**A skill is appropriate when…**:
- Task requires judgment, branching, or dynamically composing tools
- Task should be automatically done based on needs of agent
- Agent needs to use skill-associated files/scripts/references
- Task is reusable across many sessions

**A command is appropriate when…**:
- Task is a fixed prompt template run on demand
- You want a `/shortcut` that injects context (args, shell output, files)
- Output format is always the same

**An agent is appropriate when…**:
- You need a persistent specialised assistant workflow
- You want a different model, temperature, or tool set
- You want to restrict or expand permissions (tool access, mcp, ..) beyond defaults

NOTE: Only **skills** support companion files (`references/`, `scripts/`, `assets/`, `templates/`).
Agents and commands use single `.md` file — all content must be self-contained.

**A snippet is appropriate when…**:
- You want reusable static text injected anywhere in a message (not just first position)
- Content is small, self-contained, and has a single responsibility
- You want to DRY up recurring prompt patterns or instructions

Based on artefact type, read one of following references for full spec of that type.
- skill: `./references/skill-anatomy.md`
- command: `./references/command-anatomy.md`
- agent: `./references/agent-anatomy.md`
- snippet: load `snippets` skill for full spec

If skill will use a script, read `./references/skill-with-script.md`.

### Should this even be an OpenCode config artefact?

Before proceeding, determine whether an OpenCode artefact is the right 'tool' for the job.

An OpenCode artefact is NOT appropriate for tasks that are:
- Fully deterministic → suggest to write a script (`scripts/`, `Makefile`, CI workflow)
- Always identical → suggest to use a template or code generator
- Run unattended in CI/CD → suggest to use a pipeline action, not an agent
- Simple enough to be a one-liner → suggest to write command in `AGENTS.md`

If requested need appears to 'violate' these rules, suggest user toward alternative solution.

## 2. `Phase:discover` — Gather reqs through focused questions

Ask focused questions until you have enough requirements to draft.
Limit to 3 rounds.

For all artefact types:
- What is the single responsibility of the artefact?
- Project-scoped or global/personal?
- Any constraints, failure modes, or edge cases?
  (these may appear during review iterations or later as artefact used in different contexts)

For skills additionally:
- What inputs does agent receive? What should it produce?
- Are there reference docs, scripts, or templates it needs?
- Are there sub-scenarios where only part of the instructions applies?
  If yes: apply progressive disclosure — read `./references/skill-anatomy.md` § Progressive Disclosure
  for the pattern (split criteria, conditional trigger syntax).

For agents additionally:
- Primary agent or subagent? Hidden from autocomplete? Should have isolated context?
- Which tools should be allowed, denied, or ask-before-use?
- Should it use a different model or temperature?

For commands additionally:
- What arguments does it take? (if any)
- Does it need shell output or file content injected?
- Should it run in a subagent session to avoid polluting context?

For snippets additionally:
- What is trigger name? any aliases?
- Should content expand inline, or use `<append>`/`<prepend>` blocks?
- Does it need shell command output injected (`` !`cmd` ``)?

## 3. `Phase:draft` — Plan structure; setup `$draftpath`; Iterate on draft

**First**: establish `$draftpath`.
- New artefact: use `/tmp/opencode_crafter/<type>-<name>/`.
- Update: `$draftpath` = `$existingpath` (path where artefact already lives) — no copy needed.

Write all draft files to `$draftpath` as soon as they exist.
**Writing files early is critical** — it protects draft content from context compression in long sessions.
Keep them updated after every meaningful change.

Do not output draft content inline. Tell user where to inspect it:
> Draft written to `$draftpath/<filename>` — open to inspect.

Note any open questions or tradeoffs.

Draft prose should be lean and terse — imperative, no filler.
State intent and constraints only; do not prescribe output structure or section layout.
NOTE: Use light caveman mode for drafting of artefact files, as well as all comms with user during crafting process.
(load `caveman` skill for more info)

Ask: *Does this match what you had in mind?*

Iterate until user explicitly confirms the draft is ready.
Then proceed to `Phase:scripts` (for skill, if scripts needed) or `Phase:review`.

## 3.5. `Phase:scripts` (if needed) — Script POC & iterate via subagent

Skip phase if artefact does NOT have script.

Invoke `opencode-skill-script-crafter` subagent via `task` tool.
Pass in prompt:
- `$draftpath` (agent works there), SKILL.md there used for script's interface spec
- Only extra context not captured in SKILL.md: behavioral notes, edge cases, impl details
  discussed in `Phase:discover/draft` that SKILL draft intentionally omits.

Subagent writes scripts and tests into `$draftpath`, iterates with user, and returns when confirmed.

Only proceed to `Phase:review` once user confirms scripts are done.
Script review does not count as full-artefact review — `Phase:review` covers the complete artefact.
If user abandons script work mid-phase, note any unresolved scripts and carry the gap into `Phase:review`.

## 4. `Phase:review` — Review & iterate with user via subagent

Invoke `opencode-artefact-reviewer` subagent via `task` tool.
Pass in prompt:
- Artefact type and name
- `$draftpath` (reviewer reads and edits files there)
- For updates: which parts changed, so reviewer can focus

Subagent reads and edits files at `$draftpath`, asks user questions via `question` tool.
Reviewer handles writing-style conformance — do not pre-apply style yourself.
For updates: tell reviewer to focus on changed sections and verify coherence with unchanged parts.
Continue until user confirms or types "done". No round limit.

After iterations, briefly reflect on diff between initial & final draft.
Ask: *Ready to write `<name>` to `$installpath` ?* (skip for updates — `$draftpath` = `$existingpath`)

For updates: once user confirms, retitle session with `done:` prefix (see Session titling above).

## 5. `Phase:ship` — Write (new artefacts only)

Skip this phase for updates — `$draftpath` = `$installpath`, files are already in place.

Copy all files from `$draftpath` to `$installpath`.
For skills, create full directory structure including any `./references/`, `./scripts/`, `./assets/`, `./templates/` or `tests/` dirs.

After confirming all files are written successfully, clean up:
Must use `trash $draftpath` (never `rm -rf`).

Retitle session with `done:` prefix (see session titling conventions above).
