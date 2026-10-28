# Pitfalls

Traps hit while building the local plugins, kept so they are not hit again.

- A raw `useKeyboard` listener created in an `app`-slot component did not fire in that context.
  The host keymap layer is the mechanism that works: register commands with `bind` strings through `context.keymap.layer(...)`.
- Creating a keymap layer directly in `setup` failed with `Keymap.Provider is missing`.
  Creating it from a component rendered into the `app` slot works, because that render runs inside the host keymap provider.
- A global, ungated binding shadows the same key everywhere, including the prompt.
  Wrap every plugin key in `enabled: () => ...` so it fires only in the states the plugin owns.
- Split a plugin's keys across a `global` layer and a pushed mode when a release key must hand keys back.
  Putting everything in one global layer leaves the release with nothing to release.
- `before` and `after` on the `app` slot are silently no-ops: the root has no siblings.
  Use `prepend` or `append`.
- `ui.panel.open` returns `false` unless the current route is a session.
  A dock toggle that ignores the return value leaves the panel invisible with no way back to the floating surface.
- An `app`-slot overlay is positioned against the host main area, which stops above the bottom bars, while `useTerminalDimensions` reports the whole terminal.
  Expect drift near the bottom edge and recompute on resize.
- Do not install the optional peers (`@opentui/*`, `solid-js`, `@opencode/theme`) just to get types; they can shadow the host instances.
  Read the installed `node_modules/@opencode/plugin/dist/tui/*.d.ts` for the contract instead.
- The host is the first real compile for a local `.tsx` plugin; there is no local typecheck or test harness.
  Reload, watch the TUI, and check `~/.local/share/opencode/log/opencode.log` filtering `role=cli`.
- Theme palette names are optional at runtime even though `ResolvedTheme` types `hue` as a full record.
  `theme.hue.yellow[400]` on a theme without that palette throws `undefined is not an object`.
  Optional-chain the palette and fall back to an ANSI color name.
- A slot render error is contained and names the slot: `<plugin>.tui crashed in slot <slot>: …`.
  Use that path to identify which surface broke.
- Theme failures can appear only on an interactive state.
  A token first read on hover is not exercised by loading the plugin, so smoke-test hover and click.
- A host state file can be shared across clients while the host keeps a per-client in-memory view.
  Reading it then reports other clients' changes, and a click that dispatches the host command does
  nothing because that client's list is empty.
  Gate on the host command's reachability (`context.keymap.commands()`) instead.
