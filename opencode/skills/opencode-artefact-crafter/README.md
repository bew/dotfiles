# opencode-artefact-crafter

Guides an OC agent through a structured, phase-based workflow to **create or update** OpenCode
artefacts: skills, agents, commands, and snippets.

Handles the full lifecycle — from classifying the right artefact type, through discovery,
drafting, optional script work, review, and final install.

## Phases

| # | Phase | What happens |
|---|---|---|
| 1 | `classify` | Identify artefact type; detect create vs. update |
| 2 | `discover` | Gather requirements through focused questions |
| 3 | `draft` | Write files to `$draftpath`; iterate with user |
| 3.5 | `scripts` _(if needed)_ | POC & iterate on scripts via subagent |
| 4 | `review` | Review & refine with user via subagent |
| 5 | `ship` | Copy to `$installpath` (new artefacts only) |

Full phase logic is in [`SKILL.md`](./SKILL.md).

## Dependencies

### Skills

| Skill | Required? | Used for |
|---|---|---|
| `snippets` | conditional — if creating a snippet | classify phase: loads snippet spec |
| `caveman` | optional (recommended) | terse drafting & communication during crafting |
| `bew-inline-callout-style` | optional (reference) | callout block conventions in artefact prose |

### Agents

Both agents must be installed at `~/.config/opencode/agents/` or `.agents/agents/`.

| Agent | Required? | Used in phase |
|---|---|---|
| `opencode-artefact-reviewer` | required | `Phase:review` |
| `opencode-skill-script-crafter` | conditional — if skill has scripts | `Phase:scripts` |

## Usage examples

- `Create a skill that monitors my git log and summarizes recent changes`
- `Draft a command to summarize the current PR diff`
- `Add retitle support to the crafter skill`
- `Edit the agent-stuck skill to handle a new case`
- `Create a new agent for reviewing OpenCode artefacts`

## Reference files

Companion docs loaded on demand by the agent (not read upfront):

| File | Purpose |
|---|---|
| [`references/classify-new.md`](./references/classify-new.md) | Artefact type decision rules & gate checks |
| [`references/skill-anatomy.md`](./references/skill-anatomy.md) | Full skill spec: layout, frontmatter, progressive disclosure |
| [`references/agent-anatomy.md`](./references/agent-anatomy.md) | Agent spec: model, tools, permissions |
| [`references/command-anatomy.md`](./references/command-anatomy.md) | Command spec: args, injection, subagent |
| [`references/skill-with-script.md`](./references/skill-with-script.md) | Extra rules when skill includes scripts |
| [`references/phase-scripts.md`](./references/phase-scripts.md) | Phase:scripts subagent handoff instructions |
| [`references/phase-review.md`](./references/phase-review.md) | Phase:review subagent handoff instructions |
| [`references/phase-ship.md`](./references/phase-ship.md) | Phase:ship copy & cleanup instructions |
| [`references/writing-style.md`](./references/writing-style.md) | Tone, formatting, length targets for artefact prose |
