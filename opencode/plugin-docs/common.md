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
  Keep its `@opencode/plugin` version in sync with the host's own version
  (`opencode2 --version`).
- The id convention is `<name>.<role>`, e.g. `acme.server`, `acme.cli`, or `acme.tui`.
- Published plugins declare `exports` with a `./tui` entry and add the OpenTUI peers
  `@opentui/core`, `@opentui/solid`, and `solid-js`.
  Never install those peers for a published plugin: a local copy shadows the host
  instance, which pins their versions (see `pitfalls.md`).
- A local plugin may depend on `@opentui/core` alone — no `@opentui/solid`, no
  `solid-js`, since the host provides the JSX runtime.
  That is what lets OpenTUI's color and renderable types resolve in the editor and its
  modules load under `bun test`.
  Keep the copy in sync with the OpenTUI version OpenCode bundles: the `@opentui/core`
  entry in the catalog of OpenCode's root `package.json`.
  A mismatched copy is a second `@opentui/core` instance next to the host's own, and the
  colors it builds cross into the host renderer.
- Register a published plugin in `opencode.json` `plugins`; use `cli.json` `plugins`
  for a CLI-only package that must stay active against remote servers.

## Rules we depend on

- `setup` may return a cleanup function, and anything registered from a reactive scope dies with that scope.
  Slots, keymap layers, routes, and panels therefore need no manual disposal when they are created inside a component.
- Re-registering on a state change means disposing the previous registrations
  first; keep each kind in its own set of disposers.
- Keep width maths, parsing, and state derivation in modules free of host and OpenTUI
  Solid types.
  `bun test` covers those modules, while a `.tsx` component has neither a test path nor
  a local typecheck.
