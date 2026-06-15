# Integrations

## Zsh Plugin

Zsh plugin: single keybind to show `later ls` output inline in terminal without leaving current context.

### Behavior

- Keybind (suggested: `<prefix>l`) runs `later ls` (here view) and displays output above current prompt line.
- Output is read-only — no interaction.
- Second press / any key dismisses.
- Does not run on cd or prompt; keybind-only.

### Here view in Zsh context

Output matches `later ls` default:
- Item lines for Active Scope.
- Summary block for other scopes (scope name + level counts).

Lets user glance at local tasks without leaving shell session.

### Implementation notes

- Use zsh widget (`zle`) bound to key sequence.
- Run `later ls` in subshell, capture output, display via `zle -M` or similar.
- Widget name: `later-show-here` (suggested).

---

## OpenCode Plugin

OC plugin exposes `later` on two surfaces: slash commands (user-triggered) + agent tools (autonomous).
Defined as OC plugin in `opencode/plugins/later/`.

### Slash commands

One command per Level, named `/later-<level>`.

| Command | Equivalent CLI |
|---|---|
| `/later-next` | `later add --when next ...` |
| `/later-soon` | `later add --when soon ...` |
| `/later-someday` | `later add --when someday ...` |
| `/later-maybe` | `later add --when maybe ...` |

Each command accepts free-form text as body.
`kind` extracted from leading keyword if matches alias (e.g. `/later-next fix the symlink` → kind=`fix`).
Scope auto-detected from OC session context (current repo if known, else unscoped).

### Agent tools

OC tool definitions callable by agent mid-task without user invoking a slash command.

| Tool | Args | Description |
|---|---|---|
| `later_add` | `when`, `kind`, `text`, `scopes?` | Add item to any level |
| `later_ls` | `view?`, `when?` | List items, returns text output |

Agent uses `later_add` to stash deferred work mid-task (e.g. note a `fix` without stopping current task).
`later_ls` lets agent check what's queued before adding duplicate.

NOTE: Agent tools call `later` binary directly — no separate storage logic in OC plugin.
