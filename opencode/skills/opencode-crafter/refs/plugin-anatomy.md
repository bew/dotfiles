# Plugin Anatomy

JavaScript/TypeScript module that hooks into OpenCode events to extend its behavior.

**REQUIRED**: Before drafting any plugin, fetch and read the official documentation:
- https://opencode.ai/docs/plugins/ — plugin structure, events, examples
- https://opencode.ai/docs/sdk/ — `client.*` API reference (when plugin uses the SDK client)

These pages contain essential details and examples. Do not skip.

Prefer **TypeScript** (`.ts`) over JavaScript (`.js`).

## Install paths

| Source | Path / config |
|---|---|
| Project-local | `.opencode/plugins/<name>.ts` — auto-loaded |
| Global | `~/.config/opencode/plugins/<name>.ts` — auto-loaded |

Only top-level `.ts`/`.js` files are loaded — subdirectories are ignored.

**To add a README**: place it alongside the plugin as `<name>.README.md` (e.g. `my-plugin.README.md`).

**To split a complex plugin across files**: use a thin shim as the entry point that imports from a subdir:

```
plugins/
  my-plugin.ts          ← auto-discovered entry (shim)
  my-plugin/
    main.ts
    helpers.ts
```

`my-plugin.ts`:
```ts
export { default } from "./my-plugin/main"
```

NOTE: for global scope, plugins are found in `opencode/plugins` in my `dotfiles` repo.
Use this relative path instead for edits if in the `dotfiles` repo.

Load order: global config → project config → global plugin dir → project plugin dir.

## Basic structure

```ts
import type { Plugin } from "@opencode-ai/plugin"

export const MyPlugin: Plugin = async ({ project, client, $, directory, worktree }) => {
  return {
    // hook name: handler function
    "tool.execute.before": async (input, output) => { /* ... */ },
  }
}
```

Context fields available in the plugin function:

| Field | Description |
|---|---|
| `project` | Current project information |
| `directory` | Session working directory |
| `worktree` | Git worktree root |
| `client` | OpenCode SDK client — interact with AI, sessions, TUI, etc. |
| `$` | [Bun shell API](https://bun.com/docs/runtime/shell) for running commands |

## Events (hooks)

Return an object mapping event names to async handler functions.
Full event list with handler signatures: https://opencode.ai/docs/plugins/#events
Fetch that page before using any event not listed below.

Key categories and selected events:

| Category | Events |
|---|---|
| Tool | `tool.execute.before`, `tool.execute.after` |
| Shell | `shell.env` |
| Session | `session.created`, `session.idle`, `session.compacted`, `session.error` |
| File | `file.edited`, `file.watcher.updated` |
| Message | `message.updated`, `message.part.updated` |
| Permission | `permission.asked`, `permission.replied` |
| TUI | `tui.prompt.append`, `tui.command.execute`, `tui.toast.show` |
| Experimental | `experimental.session.compacting` — inject/replace compaction prompt |

Handler signature: `async (input, output) => void`
- `input`: read-only original values
- `output`: mutable — modify to change behavior
- Throw to abort the operation (e.g. in `tool.execute.before`)

## Adding custom tools via plugin

Plugins can register tools alongside hooks:

```ts
import { type Plugin, tool } from "@opencode-ai/plugin"

export const MyPlugin: Plugin = async (ctx) => {
  return {
    tool: {
      mytool: tool({
        description: "...",
        args: { foo: tool.schema.string() },
        async execute(args, context) { return "result" },
      }),
    },
  }
}
```

Prefer standalone tool files (see `tool-anatomy.md`) unless the tool is tightly coupled to plugin hooks.

## Dependencies

Not supported in this setup. If the user needs external packages, ask what they want to do instead.

