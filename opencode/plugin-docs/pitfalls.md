# Pitfalls

Traps hit while building the `ui-tester` plugin, kept so they are not hit again.

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
- An `app`-slot overlay is positioned against the host main area, which stops above the bottom bars, while `useTerminalDimensions` reports the whole terminal.
  Expect drift near the bottom edge and recompute on resize.
- Do not install the optional peers (`@opentui/*`, `solid-js`, `@opencode/theme`) just to get types; they can shadow the host instances.
  Read the installed `node_modules/@opencode/plugin/dist/tui/*.d.ts` for the contract instead.
- The host is the first real compile for a local `.tsx` plugin; there is no local typecheck or test harness.
  Reload, watch the TUI, and check `~/.local/share/opencode/log/opencode.log` filtering `role=cli`.
