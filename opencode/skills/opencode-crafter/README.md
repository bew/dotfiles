# opencode-crafter

Guides an OC agent through a structured, phase-based workflow to **create or update** OpenCode
artefacts: skills, agents, commands, and snippets.

Handles the full lifecycle — from classifying the right artefact type, through discovery,
drafting, optional script work, review, and final install.

## Phases

| # | Phase | What happens |
|---|---|---|
| 1 | `Phase:Classify` | Identify artefact type; detect create vs. update |
| 2 | `Phase:Discover` | Gather requirements through focused questions |
| 3 | `Phase:Draft` | Write files to `$draftpath`; iterate with user |
| 3.5 | `Phase:Scripts` _(if needed)_ | POC & iterate on scripts via subagent |
| 4 | `Phase:Review` | Review & refine with user via subagent |
| 5 | `Phase:Ship` | Copy to `$installpath` (new artefacts only) |

Full phase logic is in [`SKILL.md`](./SKILL.md).

## Dependencies

### Skills

| Skill | Required? | Used for |
|---|---|---|
| `snippets` | conditional — if creating a snippet | classify phase: loads snippet spec |
| `caveman` | optional (recommended) | terse drafting & communication during crafting |
| `bew-inline-callout-style` | optional (reference) | callout block conventions in artefact prose |

### Agents

Agents must be installed at `~/.config/opencode/agents/` (global) or `.opencode/agents/` (project-scoped).

| Agent | Required? | Used in phase |
|---|---|---|
| `opencode-reviewer` | required | `Phase:Review` |
| `opencode-skill-script-crafter` | conditional — if skill has scripts | `Phase:Scripts` |

## Usage examples

> Create a skill that monitors my git log and summarizes recent changes
> Draft a command to summarize the current PR diff
> Add retitle support to the crafter skill
> Edit the agent-stuck skill to handle a new case
> Create a new agent for reviewing OpenCode artefacts

## Reference files

Companion docs loaded on demand by the agent (not read upfront):

| File | Purpose |
|---|---|
| [`refs/classify-new.md`](./refs/classify-new.md) | Artefact type decision rules & gate checks |
| [`refs/discover-questions.md`](./refs/discover-questions.md) | `Phase:Discover` question set |
| [`refs/skills-related/anatomy.md`](./refs/skills-related/anatomy.md) | Full skill spec: layout, frontmatter, progressive disclosure |
| [`refs/skills-related/skill-phases.md`](./refs/skills-related/skill-phases.md) | Skill-specific phase structure & crafter integration |
| [`refs/rules-for-steps-phases-headers.md`](./refs/rules-for-steps-phases-headers.md) | Phase naming, named steps, gates, reference integrity |
| [`refs/skills-related/with-script.md`](./refs/skills-related/with-script.md) | Extra rules when skill includes scripts |
| [`refs/agent-anatomy.md`](./refs/agent-anatomy.md) | Agent spec: model, tools, permissions |
| [`refs/command-anatomy.md`](./refs/command-anatomy.md) | Command spec: args, injection, subagent |
| [`refs/phases/scripts.md`](./refs/phases/scripts.md) | `Phase:Scripts` subagent handoff instructions |
| [`refs/phases/review.md`](./refs/phases/review.md) | `Phase:Review` subagent handoff instructions |
| [`refs/phases/ship.md`](./refs/phases/ship.md) | `Phase:Ship` copy & cleanup instructions |
| [`refs/rules-for-writing.md`](./refs/rules-for-writing.md) | Tone, formatting, length targets for artefact prose |
