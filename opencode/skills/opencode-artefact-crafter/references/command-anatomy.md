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

Command description should succinctly mention the semantic of the args to help user fill them on use if needed.

**Convention**: always annotate the `subtask:` line:
- `subtask: true # isolated context!`
- `subtask: false # shared context!`

## Body (template)

The body is the prompt template.

It supports various injections:

**Arguments**
```
$ARGUMENTS      — full argument string passed after the command name
$1, $2, $3, …   — positional arguments (split on whitespace)
```

**Decide first: are args required or optional?**

*Required* — command cannot function without them. Guard at the top:
```
If no argument is provided (i.e. `$ARGUMENTS` is empty), output:
"Usage: /cmd-name <what-is-needed>"
Then stop.
```

*Optional* — command degrades gracefully when args are absent.
Pick an injection form:

**Form 1 — Inline optional** (for a focus hint, filter, or short free-text):
```
Additional context (may be empty): $ARGUMENTS
If provided, treat it as a focus hint — weight your analysis toward it.
```

**Form 2 — Fenced pre-fill block** (for structured/multiline context that may answer earlier questions):
`````
## Additional user context

May be empty. If non-empty, use to pre-fill answers and skip corresponding questions.

```
$ARGUMENTS
```
`````
Place this section at the end of the command body.

**Form 3 — Positional `$1`, `$2`** (when args have distinct semantic roles):
```
Target file: $1
Output format: $2
```
Example invocation: `/summarise src/auth.ts json`
→ `$1` = `src/auth.ts`, `$2` = `json`
Use named labels above each placeholder so the injected values read naturally in context.

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
