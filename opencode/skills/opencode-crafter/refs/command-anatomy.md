# Command Anatomy

Markdown file defining a reusable prompt template, triggered by `/name` in TUI.

Official documentation: https://opencode.ai/docs/commands/

## Install paths

| Scope | Path |
|---|---|
| Project-scoped | `.opencode/commands/<name>.md` |
| Global | `~/.config/opencode/commands/<name>.md` |

Filename (without `.md`) becomes command name.

NOTE: for global scope, the commands are found in `opencode/commands` in my `dotfiles` repo.
Use this relative path instead for edits if in the `dotfiles` repo.

## Frontmatter

```yaml
---
description: string         # shown in TUI next to the name when typing /
subtask: true | false       # force subagent invocation (isolates context)
agent: agent-name           # optional — which agent handles this command
model: provider/model-id    # optional model override
---
```

Description should mention arg semantics to help user fill them on use.

**Convention**: always annotate the `subtask:` line:
- `subtask: true # isolated context!`
- `subtask: false # shared context!`

## Body (template)

Prompt template.

### Supported injections

#### Shell injection
```
!`command`  — replaced with stdout of the shell command at invocation time
```
Example: `` !`git log --oneline -10` `` injects the last 10 commits.

#### File references
```
@path/to/filename  — injects the file content inline
```
Example: `@src/api/routes.ts`

#### Arguments
```
$ARGUMENTS      — full argument string passed after the command name
$1, $2, $3, …   — positional arguments (split on whitespace)
```

**Decide first: are args required or optional?**

*Required* — command cannot function without them. Guard at top:
```
If no argument is provided (i.e. `$ARGUMENTS` is empty), output:
"Usage: /cmd-name <what-is-needed>"
Then stop.
```

*Optional* — degrades gracefully when args absent.

**Pick / Ask user to choose injection form if need unclear**:

*Form 1 — Inline optional* (focus hint, filter, or short free-text):
```
Additional context (may be empty): $ARGUMENTS
If provided, treat it as a focus hint — weight your analysis toward it.
```

*Form 2 — Fenced pre-fill block* (structured/multiline context that may answer earlier questions):
`````
## Additional user context

May be empty. If non-empty, pre-fill answers & skip corresponding questions.

```
$ARGUMENTS
```
`````
Place at end of command body.

*Form 3 — Positional `$1`, `$2`* (args with distinct semantic roles):
```
Target file: $1
Output format: $2
```
Example invocation: `/summarise src/auth.ts json`
→ `$1` = `src/auth.ts`, `$2` = `json`
Use named labels above each placeholder so injected values read naturally.
