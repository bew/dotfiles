# Agent Anatomy

Markdown file configuring a specialised AI assistant.

Official documentation: https://opencode.ai/docs/agents/

## Install paths

| Scope | Path |
|---|---|
| Project-scoped | `.opencode/agents/<name>.md` |
| Global | `~/.config/opencode/agents/<name>.md` |

Filename (without `.md`) becomes agent name, usable via `@mention`.

NOTE: for global scope, the agents are found in `opencode/agents` in my `dotfiles` repo.
Use this relative path instead for edits if in the `dotfiles` repo.

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

Markdown body is agent's system prompt. Write as direct instructions.
Before writing body: read <./rules-for-steps-phases-headers.md> for naming, structure, phase gates, and when named steps are required.

## Modes

| Mode | Usage |
|---|---|
| `primary` | Main agent; cycle with Tab or `switch_agent` keybind |
| `subagent` | Invoked via `task` tool (or `@mention`, if not hidden); runs in a child session with isolated context |
| `all` | Can be used as either (default) |

**Convention**: always annotate the `mode:` line:
- `mode: subagent # isolated context!` — subagent has no access to caller's history
- `mode: primary  # shared context!`
- `mode: all      # context depends on invocation`

## Subagent interaction

When subagent uses `question` tool, execution pauses & prompt surfaces to user in child session.
Navigate with:
- `<Leader>+Down` — enter first child session
- `Right` / `Left` — cycle child sessions
- `Up` — return to parent

## Task permissions

Control which subagents may be invoked via `task` tool using glob patterns:

```yaml
permissions:
  task:
    "*": deny
    "skill-reviewer": allow
```
