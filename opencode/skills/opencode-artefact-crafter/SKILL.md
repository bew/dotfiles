---
name: opencode-artefact-crafter
description: |
  Load when the user asks to create, update, edit, or refactor any OpenCode (OC)
  artefact: skills, agents, or commands — including modifying an existing one.
  Triggers examples: "create a skill", "create a skill to …", "update the X skill",
  "add Y to the OC cmd Z", "edit the W agent", "update the crafter skill".
  Guides the user through discovery, drafting, and iterative refinement.
---

# OpenCode Crafter

Helps users design & create OpenCode artefacts: **skills**, **agents**, **commands**.

Work in multiple phases:

1. **Artefact type** — identify right artefact type for the need
2. **Discover** — gather requirements through focused questions
3. **Draft** — plan artefact structure in-chat
4. **Iterate** — refine with user via `opencode-artefact-reviewer` subagent
5. **Write** — commit final files

No files are written until the last phase.

---

## Phase 1 — Identify the artefact type

NOTE: If the target artefact already exists, treat this as an update.
Use the existing file as the starting draft for Phase 3 but focus on the requested changes.
Still go through all remaining phases.

Ask user what they want to create if not already clear. Use decision table below to confirm right artefact type.

**A skill is appropriate when…**:
- Task requires judgment, branching, or dynamically composing tools
- Task should be automatically done based on needs of the model
- Agent needs to use skill-associated files/scripts/references
- Task is reusable across many sessions

**A command is appropriate when…**:
- Task is a fixed prompt template run on demand
- You want a `/shortcut` that injects context (args, shell output, files)
- Output format is always the same

**An agent is appropriate when…**:
- You need a persistent specialised assistant workflow
- You want a different model, temperature, or tool set
- You want to restrict or expand permissions (tool access, mcp, ..) beyond the default

Based on artefact type, read one of the following references for full spec of that type.
- skill: `./references/skill-anatomy.md`
- command: `./references/command-anatomy.md`
- agent: `./references/agent-anatomy.md`

### Should this even be an OpenCode config artefact?

Before proceeding, determine whether an OpenCode artefact is the right 'tool' for the job.

An OpenCode artefact is NOT appropriate for tasks that are:
- Fully deterministic → suggest to write a script (`scripts/`, `Makefile`, CI workflow)
- Always identical → suggest to use a template or code generator
- Run unattended in CI/CD → suggest to use a pipeline action, not an agent
- Simple enough to be a one-liner → suggest to write command in `AGENTS.md`

If requested need appears to 'violate' these rules, suggest user toward alternative solution (or let user force).

---

## Phase 2 — Discover

Ask focused questions until you have enough to draft. Limit to two rounds.

For all artefact types:
- What is the single responsibility?
- Project-scoped or global/personal?
- Any constraints, failure modes, or edge cases?
  (these may appear during review iterations or later as the thing is used in different contexts)

For skills additionally:
- What inputs does agent receive? What should it produce?
- Are there reference docs, scripts, or templates it needs?

For agents additionally:
- Primary agent or subagent? Hidden from autocomplete? Should have isolated context?
- Which tools should be allowed, denied, or ask-before-use?
- Should it use a different model or temperature?

For commands additionally:
- What arguments does it take? (if any)
- Does it need shell output or file content injected?
- Should it run in a subagent session to avoid polluting context?

---

## Phase 3 — Draft (in-chat, no files yet)

Present draft as a fenced markdown block, labeled:
````
Draft: <artefact-type>/<name>
````
(Always use 4 backticks when showing artefact, so nested code blocks don't break formatting)

Include proposed frontmatter & full body. Note any open questions or tradeoffs.
Ask: *Does this match what you had in mind?*

If the user confirms or requests only minor adjustments, proceed immediately to Phase 4 — no permission needed.

---

## Phase 4 — Review and iterate via `opencode-artefact-reviewer` subagent

Once draft shape is agreed, read `./references/writing-style.md` & apply it to all artefact bodies.
Always keep these rules in mind when making edits.

Invoke `opencode-artefact-reviewer` subagent via `task` tool:
```
task: refine the <type> draft for <name>
```
Subagent writes draft to test path, asks user questions via `question` tool, applies feedback.
Returns only the tmp path — read file from there as needed. Do not expect file content in response.
Continue until user confirms or types "done". No round limit.

After the loop, reflect shortly on diff between initial & final draft.
Ask: *Ready to write $artefact to '$installpath' ?*

---

## Phase 5 — Write

Write all files.
For skills, create full directory structure including any `./references/`, `./scripts/`, `./assets/`, or `./templates/` dirs.

Clean up any test directory used during iterations.
