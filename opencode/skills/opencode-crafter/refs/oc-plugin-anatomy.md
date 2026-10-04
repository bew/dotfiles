# oc-plugin Anatomy

An OpenCode plugin.
OpenCode loads it to add behavior — it can register tools and/or hook into events.

Official documentation — read before drafting any plugin:
- https://opencode.ai/v2/docs/build/plugins — structure, context domains, transforms, hooks, tool registration

## Install paths

`$OC_configroot/plugins/<name>/`

- `index.ts` — entry point (required)
- `README.md` — companion documentation (required)
- `<helpers>.ts` — optional modules imported by `index.ts`

Plugins under `plugins/` are loaded automatically, in global or project scope.
No config entry and no `package.json` are needed.

To load a plugin from another location or as a package, list it under `plugins` in
`opencode.json(c)`.

## Conventions

- **`README.md` is required** — explain what the plugin does, why, and any important user-facing behavior.
- **Helper modules allowed** — extra `.ts` files in the plugin directory, imported from `index.ts`.
- **`codemode: true` by default** — so registered tools join the Code Mode catalog.
  Use false and mention why as inline comment if user declined it.
- **Prefer `node:` builtins** — use Node core modules for runtime needs.

## Shape

A plugin default-exports a definition with:
- `id` — stable identifier
- `setup(ctx)` — runs once at load; may return a cleanup function

`setup` registers behavior through the context domains (for example `ctx.tool.transform` for tools).
Callbacks that edit a domain registry (such as the `editor` passed to `ctx.tool.transform`) are synchronous — do any I/O before registering.

See <./oc-tool-anatomy.md> for the oc-tool-specific angle.
