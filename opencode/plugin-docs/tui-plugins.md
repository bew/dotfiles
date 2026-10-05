# TUI plugins

The terminal surface.
The shared base is in `common.md`; the server side is in `server-plugins.md`.

## Entry and rendering

- The TUI entry is a `.tsx` file; JSX compiles through the runtime Bun loader, so it works without a local `tsconfig`.
- Open every render module with `/** @jsxImportSource @opentui/solid */` so JSX targets the OpenTUI Solid runtime.
- Render functions return OpenTUI Solid JSX; call `usePlugin()` inside a component rendered by a slot, route, or dialog to reach `context`.
- `@opentui/*`, `solid-js`, and `@opencode/theme` are host-resolved peers, not installed locally.
  Do not add them to the repo `package.json`: a local copy can shadow the host instance (OpenTUI pins a `solid-js` version).
  The cost is no local typecheck.

## Slots

`context.ui.slot(claim)` returns a disposer.
A claim is a `render` function plus exactly one placement key.

Paths and the input their render receives:

- `app` — no fields.
- `home.footer`, `home.footer.status` — no fields.
- `prompt.footer`, `prompt.footer.status`, `prompt.footer.file` — `sessionID?`, `mode`, `showDetails`.
- `session.composer.top` — `sessionID`.
- `session.panel` — `PanelInput`: `name`, `sessionID`, `width`, `presentation`, `focused`, `focus()`, `close()`, `toggleFullscreen()`.
- `sidebar.content`, `sidebar.footer` — `sessionID`.

Placement semantics:

- `prepend` and `append` place first and last inside the target boundary.
- `before` and `after` place siblings outside the target boundary.
- `replace` takes over the target; its original content and inner claims are suppressed, and an ancestor replacement beats a descendant one.
- At a path the host no longer publishes, additive claims degrade to the nearest surviving ancestor and replacements are suppressed.
- `before` and `after` on `app` are no-ops: the root has no siblings.

See `overlay-slot-trick.md` for placing an element anywhere via the `app` slot.

## Commands, palette, and keymap

Register commands in a reactive layer:

```ts
context.keymap.layer(() => ({
  mode: "global",
  priority: 10,
  commands: [{ id: "acme.status", title: "Show status", palette: true, run: () => {} }],
}))
```

- The factory must be pure; OpenCode evaluates it once to validate the command shape, then reactively.
- Create the layer from a reactive scope inside the keymap provider.
  Creating it directly in `setup` can fail with `Keymap.Provider is missing`; creating it from an `app`-slot render works.
- Command fields: `id`, `title`, `description`, `group`, `enabled`, `bind`, `palette`, `slash`, `suggested`, `run`.
  Return `false` from `run` to continue keyboard dispatch.
- `enabled` gates a binding without unregistering it, so a plugin key fires only in the states the plugin owns.

### Slash commands

`slash: { name, aliases?, arguments? }`.

- With `arguments: true`, the palette inserts the command as prompt text and waits for a submit.
- Without it, the command runs immediately from the palette via Tab or Enter, like the built-in argument-less commands.

## Input modes

`context.keymap.mode.push(name)` returns a pop function.
Layers default to the `base` mode; `mode: "global"` opts out.
Pushing a mode deactivates `base` layers (the prompt's typing) while `global` layers keep running.
The exact isolation boundary is not documented, so verify it against the host.

## Surfaces

- Panel: `context.ui.panel.open(name, { presentation })`; a `session.panel` contribution renders only when `input.name` matches.
- Dialog: promise-based `alert` / `confirm` / `prompt` / `select`, or `show(render)` with `set({ size, centered })` and `clear()`.
  Do not bind `ctrl+n` or `ctrl+p`; the dialog reserves them.
- Route: `context.ui.router.register({ name, render })` returns an unregister function; navigate with `navigate({ type: "plugin", name })`.
- Toast: `context.ui.toast.show({ message, variant, duration })`.

## Theme, layout, and input

- Use semantic tokens: `theme.text.base`, `theme.text.muted`, and `theme.hue.accent[400]` for the accent.
- OpenTUI layout is Yoga flexbox; a box accepts `position="absolute"` with `top`, `left`, `right`, and `bottom`, plus `zIndex`, `border`, `padding`, and `backgroundColor`.
- An `<input>` must be focused to receive keys; gate any letter bindings on its focus so typing is not swallowed as commands.
- OpenTUI synthesises no `click`; use `onMouseDown` / `onMouseUp`.
  Alt arrives as `meta` (and `option`).
  Text is selectable by default, so set `selectable={false}` on labels.
