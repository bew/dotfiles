# Tool Anatomy

TypeScript/JS file that defines a function the LLM can call during a conversation.

**REQUIRED**: Before drafting any tool, fetch and read the official documentation:
- https://opencode.ai/docs/custom-tools/

This file contains essential details and examples. Do not skip.

Prefer **TypeScript** (`.ts`) over JavaScript (`.js`).

## Install paths

| Scope | Path |
|---|---|
| Project-scoped | `.opencode/tools/<name>.ts` |
| Global | `~/.config/opencode/tools/<name>.ts` |

NOTE: for global scope, tools are found in `opencode/tools` in my `dotfiles` repo.
Use this relative path instead for edits if in the `dotfiles` repo.

Only top-level `.ts`/`.js` files are loaded — the glob is `{tool,tools}/*.{js,ts}` (non-recursive).

**To add a README**: place it alongside the tool as `<name>.README.md` (e.g. `my-tool.README.md`).

**To split a complex tool across files**: use a thin shim as the entry point that imports from a subdir:

```
tools/
  my-tool.ts          ← auto-discovered entry (shim)
  my-tool/
    impl.ts
    schema.ts
```

`my-tool.ts`:
```ts
export { default } from "./my-tool/impl"
```

Filename (without extension) becomes the tool name.
Multiple exports per file → each export becomes `<filename>_<exportname>`.

## Structure

Use the `tool()` helper from `@opencode-ai/plugin` for type-safety:

```ts
import { tool } from "@opencode-ai/plugin"

export default tool({
  description: "What this tool does",
  args: {
    param: tool.schema.string().describe("Parameter description"),
  },
  async execute(args, context) {
    return "result"
  },
})
```

The tool definition **must** be TypeScript or JavaScript.
`execute()` can shell out to any language.

## Args

`tool.schema` is [Zod](https://zod.dev). Can also `import { z } from "zod"` directly and use a plain object (no `tool()` wrapper needed).

Common types: `.string()`, `.number()`, `.boolean()`, `.enum([...])`, `.optional()`.
Always add `.describe("...")` to each arg — it's what the LLM sees.

## Context

`execute(args, context)` receives:

| Field | Description |
|---|---|
| `directory` | Session working directory |
| `worktree` | Git worktree root |
| `agent` | Current agent name |
| `sessionID` | Session ID |
| `messageID` | Message ID |

Use `context.worktree` to resolve repo-relative paths.

## Name collisions

If tool name matches a built-in tool, the custom tool takes precedence.
Use this deliberately to wrap/restrict built-ins (e.g. a restricted `bash` wrapper).
To disable a built-in without replacing it, use [permissions](https://opencode.ai/docs/permissions/) instead.

## External packages

Not supported in this setup. If the user needs external packages, ask what they want to do instead.
