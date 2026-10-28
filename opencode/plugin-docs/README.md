# OpenCode plugin reference

Notes gathered while building the local plugins.
This folder is not a copy of the upstream docs; it is the delta against them.

Files:

- `common.md` — the local conventions, plus pointers to the shared ground.
- `tui-plugins.md` — TUI behaviours upstream does not state, or states in a way that misled us.
- `host-state-files.md` — reading and watching host-owned state files when no plugin API exists.
- `server-plugins.md` — pointers to the server surface, plus a local example.
- `pitfalls.md` — traps hit while building the local plugins.
- `overlay-slot-trick.md` — placing an element anywhere via the `app` slot.

## What belongs here

A line earns its place only if it is one of:

- not in the official docs, or
- in them but subtly wrong, or
- a local convention of this repo.

Everything else is a link.
API catalogues — context members, events, storage, dialogs, routes, tabs, theme
tokens, publish shape — live upstream and are maintained there.
A copy here drifts silently and cannot be told apart from the real thing.

The test for a new note: "would a reader who already read the upstream page learn something?"
If not, drop it.

Local examples:

- `../plugins/ui-tester/` — TUI plugin (slots, keymap, panels, overlay).
- `../plugins/stash-count/` — TUI plugin (host state file watch, hover and click, host command dispatch).
- `../plugins/git-track-new-file/` — server plugin with a tool transform.

## Sources

OpenCode V2 docs (`https://opencode.ai/v2/docs/`):

- `build/plugins` — server plugin guide: hooks, transforms, tools, context.
- `build/plugins/cli` — the TUI plugin API. Authoritative for everything except the deltas in this folder.
- `build/plugins/server` — server surface beside a TUI part.
- `build/plugins/rpc` — custom methods and events shared with clients.
- `cli/plugins` — registering CLI-only plugin packages in `cli.json`.
- `cli/config` — `cli.json` settings reference.
- `cli/keybinds` — keybind ids and defaults; source of the `ctrl+n` / `ctrl+p` dialog rule.
- `config` — `opencode.json(c)` fields.
- `troubleshooting` — service commands and log locations.
- `llms.txt` — machine-readable docs index.

OpenTUI docs (`https://opentui.com/docs/`):

- `core-concepts/keyboard` — `KeyEvent` fields, propagation, paste.
- `core-concepts/interaction` — mouse events, focus, the missing synthetic click.
- `core-concepts/layout` — flexbox layout and absolute positioning.
- `bindings/solid` — Solid binding, `jsxImportSource`, hooks, version pinning.
- `keymap/overview` — layers, priority, pending sequences.
- `keymap/solid` — `KeymapProvider`, `useKeymap`, `useBindings`.
- `components/input` — input props, events, focus.
- `components/box` — box styling props.

Types and mirrors:

- `../node_modules/@opencode/plugin/dist/tui/context.d.ts` — the exact TUI contract for the installed host version.
- `@opencode/theme` on unpkg, `dist/tui/types.d.ts` — `ResolvedTheme` tokens.
- `@opentui/core`, `@opentui/solid`, `solid-js` — host-resolved, not installed locally.
- `@opencode/plugin` RPC types — the RPC surface.
