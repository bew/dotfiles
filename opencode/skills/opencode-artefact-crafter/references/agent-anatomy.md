# Agent Anatomy

An agent is a markdown file that configures a specialised AI assistant.

Official documentation: https://opencode.ai/docs/agents/

## Install paths

| Scope | Path |
|---|---|
| Project-scoped | `.opencode/agents/<name>.md` |
| Global | `~/.config/opencode/agents/<name>.md` |

The filename (without `.md`) becomes the agent name, usable via `@mention`.

## Frontmatter

```yaml
---
description: string         # required — shown in @ autocomplete; drives auto-invocation
mode: primary | subagent | all   # default: all
hidden: true                # hide from @ autocomplete (internal subagents only)
model: provider/model-id    # optional override
temperature: 0.0–1.0        # optional
max_steps: integer          # optional — cap agentic iterations
color: "#FF5733" | primary | accent | …   # optional UI colour
permissions:
  read: allow | ask | deny
  edit: allow | ask | deny
  bash: allow | ask | deny
  task: allow | ask | deny
  skill: allow | ask | deny
  question: allow | ask | deny
  glob: allow | ask | deny
  grep: allow | ask | deny
  list: allow | ask | deny
  webfetch: allow | ask | deny
  websearch: allow | ask | deny
  lsp: allow | ask | deny
  todowrite: allow | ask | deny
  external_directory: allow | ask | deny
  doom_loop: allow | ask | deny
---
```

## Body

The markdown body is the agent's system prompt. Write it as direct instructions.

## Modes

| Mode | Usage |
|---|---|
| `primary` | Main agent; cycle with Tab or `switch_agent` keybind |
| `subagent` | Invoked via `task` tool or `@mention`; runs in a child session with isolated context |
| `all` | Can be used as either (default) |

## Subagent interaction

When a subagent uses the `question` tool, execution pauses and the prompt surfaces to the user in the child session.
Navigate with:
- `<Leader>+Down` — enter first child session
- `Right` / `Left` — cycle child sessions
- `Up` — return to parent

## Task permissions

Control which subagents an agent may invoke via the `task` tool using glob patterns:

```yaml
permissions:
  task:
    "*": deny
    "skill-reviewer": allow
```
