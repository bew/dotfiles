# bew-tui plugin

Global OpenCode V2 TUI plugin: a bundle of widgets that adjust the OpenCode TUI.
Each widget owns its topic, with its logic in unit-tested modules.

`tui-widgets/` holds the widgets `tui.tsx` composes.
Reusable pieces that know nothing about a specific widget live in `tui-toolkit/` alongside it.

Every widget degrades on its own when its source is unavailable, and those fallbacks are
best-effort rather than a stable contract.

## Widgets

Each widget owns one topic and has a README of its own; `tui.tsx` composes them into the host slots.

- [`diralias footer`](./tui-widgets/diralias/README.md) — labels the current directory as its diralias alias, split at the repository root, falling back to the host's path.
- [`git-branch label`](./tui-widgets/git-branch.README.md) — shows the git branch of the current directory, with ahead and behind markers and a dirty colouring.
- [`session stats`](./tui-widgets/session-stats/README.md) — counts turns and tools for the session and for the model's active context, with a click-to-open breakdown.
- [`running indicator`](./tui-widgets/running-indicator.README.md) — the sweep the footer draws while a session runs.

The toolkit holds what more than one widget needs:

- [`tooltip`](./tui-toolkit/tooltip/README.md) — the overlay panel that places a themed tooltip beside an anchor.
- [`spinners`](./tui-toolkit/spinners/README.md) — the shared sweep and loader views.

## Layout

This is a directory plugin, discovered automatically from the global plugins
root (`~/.config/opencode/plugins/`).
No config entry is needed, and the plugin has no manifest of its own — the config
package provides its dependencies.

- `index.ts` — server entry (a no-op).
- `tui.tsx` — TUI entry; composes the widgets and claims the host slots they
  render into.
- `tui-widgets/` — the widgets, one topic each, each with a README beside its
  entrypoint.
  A widget that spans several files
  keeps its own folder (`tui-widgets/<name>/`) and always exposes `widget.tsx` as
  its entrypoint; a single-file widget sits directly under `tui-widgets/` as
  `tui-widgets/<name>.tsx`, with `<name>.README.md` beside it.
- A widget folder holds only what its own topic needs; a piece more than one
  widget needs lives in `tui-toolkit/` instead, which also holds helpers that are
  not widgets by themselves (layout maths, anchor narrowing).
  A reusable component that spans several files follows the entrypoint rule too,
  naming its entry `component.tsx`: `tui-toolkit/tooltip/` does.
  A barrel that re-exports several components stays plural, like the spinners'
  `components.tsx`.
  These helpers are internal to this plugin, not a published surface.
- `tui-toolkit/spinners/` holds the shared spinners — the knight-rider view with
  its maths, and the braille loader — and exposes the two views through
  `components.tsx`, a re-export-only barrel so widgets have one import site.
- A widget that carries its own state or lifecycle exposes a `create*()` factory
  returning `{ render, dispose }`; `tui.tsx` calls the factory, composes the
  renders, claims the slot, and aggregates the disposers, releasing the slot
  claims first and the widget factories after.
  A stateless widget stays a plain component, like the running indicator.
- `lib/` holds unit-tested building blocks free of host and Solid types: the
  color primitives, the git-status and git-repo parsing, and the adaptive git
  poller.

Run the unit tests with `just test bew-tui` from the `opencode` directory.
There is no local typecheck, so a reload is the first real compile: the host log
reports plugin load failures, while render errors appear only in the TUI.

## OpenTUI

Widgets draw through OpenTUI: the host's `<spinner>` element and its `RGBA`
color type.
`@opentui/core` is therefore a dependency of the config package, which is what
lets those types resolve in the editor and the color modules load under
`bun test`.
Host-provided modules — `@opentui/solid`, `solid-js`, the theme — must not be
installed locally, or they shadow the host's copies.

Keep it in sync with the OpenTUI version OpenCode bundles — the `@opentui/core`
entry in the catalog of OpenCode's root `package.json`.
A mismatched copy loads as a second `@opentui/core` instance next to the host's
own, and the colors it builds cross into the host renderer.

A `box` takes `backgroundColor` while a `text` renderable takes `bg`, so a
background set with the wrong prop is ignored.
A host renderable applies its `fg` when it is created, so a colour that changes
needs a fresh renderable.
Theme palette entries can be absent at runtime, so read them through a fallback.

Footer glyphs and status counts set `selectable={false}`, so they stay
decoration; the directory path and the branch name stay selectable, so a mouse
drag copies them without the glyphs.
