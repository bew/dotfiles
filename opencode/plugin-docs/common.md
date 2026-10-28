# Common plugin ground

Shared by server and TUI plugins.
The two surfaces are in `server-plugins.md` and `tui-plugins.md`.

`Plugin.define`, the `setup` lifecycle and cleanup, context fields, typed events,
storage, packaging, and publishing are documented upstream at
`https://opencode.ai/v2/docs/build/plugins`.
This page keeps only what is local to this repo, plus the rules we depend on.

## Local conventions

- Local directory plugins are discovered at `<config-root>/plugins/<name>/`, with
  `index.ts` as the server entry and `tui.tsx` as the TUI entry.
  A TUI-only plugin still ships a server entry, so directory discovery pairs the two files.
- Local plugins need no `package.json`; OpenCode resolves `@opencode/plugin` and
  `@opencode/plugin/tui` at runtime.
  The repo `package.json` exists for editor types only, which is why an out-of-range
  version there costs nothing at runtime but blinds the types.
- The id convention is `<name>.<role>`, e.g. `acme.server`, `acme.cli`, or `acme.tui`.
- Published plugins declare `exports` with a `./tui` entry and add the OpenTUI peers
  `@opentui/core`, `@opentui/solid`, and `solid-js`.
  Never install those peers locally: a local copy shadows the host instance, which
  pins their versions (see `pitfalls.md`).
- Register a published plugin in `opencode.json` `plugins`; use `cli.json` `plugins`
  for a CLI-only package that must stay active against remote servers.

## Rules we depend on

- `setup` may return a cleanup function, and anything registered from a reactive scope dies with that scope.
  Slots, keymap layers, routes, and panels therefore need no manual disposal when they are created inside a component.
- Re-registering on a state change means disposing the previous registrations
  first; keep each kind in its own set of disposers.
