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
- Local plugins run in the host's Bun runtime, so `node:*` builtins are available (`node:fs`, `node:os`, `node:path`).

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

### Dispatching host commands

`context.keymap.dispatch(id)` runs a reachable command by ID, including a command the host registered itself.
Use it to reuse host UI instead of rebuilding it; `stash-count` dispatches `prompt.stash.list` from the count label.

- A host command may exist only in some states, or carry `enabled`.
  Dispatch then does nothing, so the plugin's own trigger condition must match the host condition.
  The stash command is enabled only while this TUI's stash is non-empty; `stash-count` gates its render on `context.keymap.commands()` containing that command.
  Reading the stash file is not a substitute: the file is shared by every TUI, while the host's list is per TUI.
- Command IDs are host internals, not a documented plugin API.
  Treat them as names that can move between releases.

### Finding host commands during development

There is no host-only accessor and no shipped command list.
`context.keymap.commands()` returns every reachable command, host and plugin together, reactive when read in a Solid computation.
Use it from a throwaway probe while crafting a plugin, not from the plugin itself.

Add a temporary component that logs the IDs, mount it in a slot, reload, read the output, then remove it:

```tsx
import { createEffect } from "solid-js";

createEffect(() => {
  const commandIDs = context.keymap.commands()
    .flatMap((command) => command.id === undefined ? [] : [command.id]);
  console.log(commandIDs.join("\n"));
});
```

Each entry also carries optional `title`, `description`, `group`, and `enabled`, so filter on those when the ID prefix is unknown.
`context.keymap.shortcuts(id)` returns the formatted shortcuts for one command, which confirms a host binding without reading the binary.

Once an ID is found, dispatch it from the real plugin with `context.keymap.dispatch(id)` and remove the probe.

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

- Prefer semantic tokens: `theme.text.base`, `theme.text.muted`, and `theme.hue.accent[400]` for the accent.
  Only declared tokens are contract; a runtime field such as `theme.text.default` is untyped and may render by accident.
- `theme.hue` declares only `accent`, `interactive`, and `neutral`.
  Other palette names such as `theme.hue.yellow` exist only when the active theme defines them.
  Dereferencing a missing palette throws `undefined is not an object` and crashes the slot at render time.
  Optional-chain and fall back to an ANSI color name: `theme.hue.yellow?.[400] ?? "yellow"`.
  When a typed semantic token fits, prefer it over a raw palette name, e.g. `theme.text.feedback.warning.base`.
- OpenTUI layout is Yoga flexbox; a box accepts `position="absolute"` with `top`, `left`, `right`, and `bottom`, plus `zIndex`, `border`, `padding`, and `backgroundColor`.
- An `<input>` must be focused to receive keys; gate any letter bindings on its focus so typing is not swallowed as commands.
- OpenTUI synthesises no `click`; use `onMouseDown` / `onMouseUp`.
  Host click handlers listen on `onMouseUp`, guard `event.button === 0`, and call `stopPropagation()` so the event does not reach the surface beneath.
  Hover uses `onMouseOver` / `onMouseOut`; the TUI has no pointer cursor, so the visual change is the affordance.
  Alt arrives as `meta` (and `option`).
  Text is selectable by default, so set `selectable={false}` on labels.
