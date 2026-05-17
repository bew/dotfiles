# Command Anatomy

A command is a markdown file that defines a reusable prompt template, triggered by `/name` in the TUI.

Official documentation: https://opencode.ai/docs/commands/

## Install paths

| Scope | Path |
|---|---|
| Project-scoped | `.opencode/commands/<name>.md` |
| Global | `~/.config/opencode/commands/<name>.md` |

The filename (without `.md`) becomes the command name.

## Frontmatter

```yaml
---
description: string         # shown in TUI next to the name when typing /
subtask: true | false       # force subagent invocation (isolates context)
agent: agent-name           # optional — which agent handles this command
model: provider/model-id    # optional model override
---
```

## Body (template)

The body is the prompt template.

It supports various injections:

**Arguments**
```
$ARGUMENTS      — full argument string passed after the command name
$1, $2, $3, …   — positional arguments
```
Example invocation:
`/summarise src/auth.ts`
→ `$1` in the command template will be replaced with `src/auth.ts`

**Shell injection**
```
!`command`  — replaced with stdout of the shell command at invocation time
```
Example: `` !`git log --oneline -10` `` injects the last 10 commits.

**File references**
```
@path/to/filename  — injects the file content inline
```
Example: `@src/api/routes.ts`
