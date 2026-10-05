# OpenCode plugin reference

Notes gathered while building the local `ui-tester` plugin.
The scope is deliberately narrow: only what this plugin needed, plus links so the same ground is not re-researched.

Plugins come in two kinds over a shared base:

- `common.md` — packaging, discovery, context, events, storage, and lifecycle.
- `tui-plugins.md` — the terminal surface: slots, keymap and commands, input modes, panels, dialogs, routes, theme.
- `server-plugins.md` — the server surface, pointers only (barely used here).
- `pitfalls.md` — the traps hit while building `ui-tester`.
- `overlay-slot-trick.md` — placing an element anywhere via the `app` slot.

Local examples:

- `../plugins/ui-tester/` — TUI plugin (slots, keymap, panels, overlay).
- `../plugins/git-track-new-file/` — server plugin with a tool transform.

## Sources

OpenCode V2 docs (`https://opencode.ai/v2/docs/`):

- `build/plugins` — server plugin guide: hooks, transforms, tools, context.
- `build/plugins/cli` — TUI plugin API: context, keymap, slots, dialogs, panels, routes, storage.
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

- `../node_modules/@opencode/plugin/dist/tui/context.d.ts` — the exact TUI contract.
- `@opencode/theme` on unpkg, `dist/tui/types.d.ts` — `ResolvedTheme` tokens.
- `@opentui/core`, `@opentui/solid`, `solid-js` — host-resolved, not installed locally.
- `@opencode/plugin` RPC types — the RPC surface.
