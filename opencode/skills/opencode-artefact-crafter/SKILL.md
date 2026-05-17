---
name: opencode-artefact-crafter
description: |
  Interactively creates/update OpenCode artefacts — skills, agents, commands.
  Use when asked to build, scaffold, design, or refine any of these.
  Guides the user through discovery, drafting, and iterative refinement.
---

# OpenCode Crafter

Helps users design and create OpenCode artefacts: **skills**, **agents**, **commands**.

Work in multiple phases:

1. **Artefact type** — identify the right artefact type for the need
2. **Discover** — gather requirements through focused questions
3. **Draft** — plan the artefact structure in-chat
4. **Iterate** — refine with the user via the `opencode-artefact-reviewer` subagent
5. **Write** — commit the final files

No files are written until the last phase.

---

## Phase 1 — Identify the artefact type

Ask the user what they want to create if not already clear. Use the decision table below to confirm the right artefact type.

**A skill is appropriate when…**:
- The task requires judgment, branching, or dynamically composing tools
- The task should be automatically done based on needs of the model
- The agent needs to use skill-associated files/scripts/references
- The task is reusable across many sessions

**A command is appropriate when…**:
- The task is a fixed prompt template run on demand
- You want a `/shortcut` that injects context (args, shell output, files)
- The output format is always the same

**An agent is appropriate when…**:
- You need a persistent specialised assistant workflow
- You want a different model, temperature, or tool set
- You want to restrict or expand permissions (tool access, mcp, ..) beyond the default

Based on the type of artefact, read one of the following references for the full spec of that type.
- skill: `./references/skill-anatomy.md`
- command: `./references/command-anatomy.md`
- agent: `./references/agent-anatomy.md`

### Should this even be an OpenCode config artefact?

Before proceeding, determine whether an opencode artefact is the right 'tool' for the job.

An OpenCode artefact is NOT appropriate for tasks that are:
- Fully deterministic → suggest to write a script (`scripts/`, `Makefile`, CI workflow)
- Always identical → suggest to use a template or a code generator
- Run unattended in CI/CD → suggest to use a pipeline action, not an agent
- Simple enough to be a one-liner → suggest to write the command in `AGENTS.md`

If the requested need appear to 'violate' these rules, suggest the user toward an alternative solution (or let the user force).

---

## Phase 2 — Discover

Ask focused questions until you have enough to draft. Limit to two rounds.

For all artefact types:
- What is the single responsibility?
- Project-scoped or global/personal?
- Any constraints, failure modes, or edge cases?
  (note that these may appear during review iterations or later as the thing is used in different
  contexts)

For skills additionally:
- What inputs does the agent receive? What should it produce?
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

Present the draft as a fenced markdown block, labeled:
````
Draft: <artefact-type>/<name>
````
(Always use 4 backticks when showing the artefact, so nested code blocks don't break formatting)

Include the proposed frontmatter and full body. Note any open questions or tradeoffs.
Ask: *Does this match what you had in mind?*

---

## Phase 4 — Review and iterate via `opencode-artefact-reviewer` subagent


Once the draft shape is agreed, read `./references/writing-style.md` and apply it to all artefact bodies.
Always keep these rules in mind when making edits.

Invoke the `opencode-artefact-reviewer` subagent via the `task` tool:
```
task: refine the <type> draft for <name>
```
The subagent writes the draft to a test path, asks the user any number of questions via the `question` tool, applies feedback.
Continue until the user confirms the artefact is correct or types "done". No round limit.

After the loop, reflect shortly on the diff between the initial and final draft.
Ask: *Ready to write $artefact to '$installpath' ?*

---

## Phase 5 — Write

Write all files.
For skills, create the full directory structure including any `./references/`, `./scripts/`, `./assets/`, or `./templates/` dirs.

Clean up any test directory used during iterations.
