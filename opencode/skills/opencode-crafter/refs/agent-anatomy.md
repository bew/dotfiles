# Agent Anatomy

Markdown file configuring a specialised AI assistant.

Official documentations:
- https://opencode.ai/v2/docs/agents/
- https://opencode.ai/v2/docs/permissions/

## Install paths

`$OC_configroot/agents/<name>.md`

Filename (without `.md`) becomes agent name, usable via `@mention`.

## Frontmatter

```md
---
description: string # required, drives auto-invocation
mode: primary | subagent | all # default: all
hidden: true # removes agent from listings and the subagent catalog, can still be called by name
# model: provider/model-id # optional override
# temperature: 0.0–1.0     # optional
# max_steps: integer       # optional — cap agentic iterations
color: "#FF5733" | primary | accent | …   # optional UI colour
permissions: [] # ordered rule list — see "Permissions" below
---
```

## Body

Markdown body is agent's system prompt. Write as direct instructions.
Before writing body: read <./rules-for-steps-phases-headers.md> for naming, structure, phase gates, and when named steps are required.

If the agent extracts structured inputs from free-form context (path, scope, hints, …):
read <./with-precise-inputs.md> for the `## Setup` pattern and input rules.

## Modes

| Mode | Usage |
|---|---|
| `primary` | Main agent; cycle with Tab or `switch_agent` keybind |
| `subagent` | Invoked via `subagent` tool (or `@mention`, if not hidden); runs in a child session with isolated context |
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

## Permissions

`permissions` is an ORDERED list of rules; the last matching rule wins.
Each rule is an inline flow map `{action, resource, effect}`.
A malformed value drops the agent — it never registers.

Every agent — custom included — starts from this ordered base policy:
```yaml
- {action: "*", resource: "*", effect: allow}
- {action: external_directory, resource: "*", effect: ask}
- {action: read, resource: "*.env", effect: ask}
- {action: read, resource: "*.env.*", effect: ask}
- {action: read, resource: "*.env.example", effect: allow}
```
Agent rules append after this base — they refine it, never replace it.
So all tools are `allow` by default; a rule is only useful to restrict or to prompt.
`question` is on by default — declare it only to `deny` it (shipped `general` does), never to enable it.

OpenCode also pre-allows `external_directory` for its managed tool-output, shell-output, temp, and global config dirs — these appear in every agent's resolved rules.

Shipped agents append their own defaults on top of the base policy:

| Agent | Appended policy |
|---|---|
| `build` | `question` allow (redundant with base) |
| `plan` | `question` allow; `edit` deny except `~/.opencode/plan/*` |
| `general` | `question` deny; `subagent` deny |
| `explore` | deny all, then allow `read`/`glob`/`grep`/`webfetch`/`websearch`; `external_directory` + `.env` ask |
| `title`, `summary` | deny all |
| `compaction` | none — base policy only |

Example:
```md
---
# ...
permissions:
  - {action: shell, resource: "*", effect: deny}
  # Deny shell by default, except for `git diff*` commands
  - {action: shell, resource: "git diff*", effect: allow}
  - {action: subagent, resource: "*", effect: deny}
---
```

| Action | Covers |
|---|---|
| `read` | file reads |
| `edit` | edit, write, patch |
| `glob`, `grep` | file/content search |
| `shell` | command execution |
| `subagent` | invoking subagents via the `subagent` tool |
| `skill` | loading skills |
| `question` | asking the user |
| `webfetch`, `websearch` | network access |
| `external_directory` | paths outside the project |
| `execute`, `<server>_<tool>` | direct tool execution, MCP tools |

Effects: `allow`, `ask`, `deny`.
The base `* allow` rule matches every action, so an unlisted tool resolves to `allow`.
`ask` only comes from an explicit rule (e.g. the base `external_directory` and `.env` rules).

`hidden` removes the agent from listings, interactive discovery, and the subagent catalog.
A hidden agent can still be launched by a caller that names it explicitly via the `subagent` tool.
So `hidden` is fine for launch-by-name-only agents — the model cannot discover it on its own.
