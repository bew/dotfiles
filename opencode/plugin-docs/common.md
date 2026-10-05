# Common plugin ground

Shared by server and TUI plugins.
The two surfaces are in `server-plugins.md` and `tui-plugins.md`.

## Packaging and discovery

A plugin is `Plugin.define({ id, setup })`, default-exported from its entry file.

- The server entry imports `Plugin` from `@opencode/plugin`; the TUI entry imports it from `@opencode/plugin/tui`.
- Local directory plugins are discovered at `<config-root>/plugins/<name>/`, with `index.ts` as the server entry and `tui.tsx` as the TUI entry.
- Local plugins need no `package.json`; OpenCode resolves `@opencode/plugin` and `@opencode/plugin/tui` at runtime.
- Published plugins declare `exports` with a `./tui` entry and add the OpenTUI peers `@opentui/core`, `@opentui/solid`, and `solid-js`.
- Register a published plugin in `opencode.json` `plugins`; use `cli.json` `plugins` for a CLI-only package that must stay active against remote servers.
- The id convention is `<name>.<role>`, e.g. `acme.server` or `acme.cli`.

## Entry

`setup(context)` runs once, may be async, and may return a cleanup function that OpenCode calls when the plugin is disabled or the runtime shuts down.

## Context

Fields a TUI plugin used:

- `context.keymap` — keymap layers and input modes.
- `context.ui` — slots, dialogs, toasts, panels, router, tabs, format.
- `context.theme` — resolved theme tokens.
- `context.renderer` — the OpenTUI renderer.
- `context.storage` — `memory` and `store`.
- `context.data` — cached server data with `sync` and `invalidate`.
- `context.client` — generated client for the connected server.
- `context.options`, `context.location`, `context.app` — plugin options, current location, and app metadata.

## Events

`context.data.on(type, handler)` subscribes to one typed event and `context.data.listen(handler)` to every server event; both return an unsubscribe function.

## Storage

- `storage.memory(key, { initial })` survives plugin reloads and is discarded when the TUI exits; it returns a synchronous `[state, update]`.
- `storage.store(key, { initial })` is durable JSON across restarts and synced across TUI instances; its `update` is async.

## Lifecycle and cleanup

- Slots, keymap layers, routes, and panels registered from a reactive scope are disposed when that scope is disposed or the plugin unloads.
- Re-registering on a state change means disposing the previous registrations first; keep each kind in its own set of disposers.
