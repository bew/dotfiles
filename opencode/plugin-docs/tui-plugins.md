# TUI plugins

The terminal surface.
The shared base is in `common.md`; the server side is in `server-plugins.md`.

The TUI API — context members, events, keymap layers, input modes, slots and their
inputs, dialogs, routes, tabs, model, theme, renderer ownership, storage, and
publishing — is documented upstream at `https://opencode.ai/v2/docs/build/plugins/cli`.
That page is the reference.
This page is the delta: what upstream does not say, or says in a way that misled us.

## Entry and rendering

- The TUI entry is a `.tsx` file; JSX compiles through the runtime Bun loader, so it works without a local `tsconfig`.
- Open every render module with `/** @jsxImportSource @opentui/solid */` so JSX targets the OpenTUI Solid runtime.
- Render functions return OpenTUI Solid JSX; call `usePlugin()` inside a component
  rendered by a slot, route, or dialog to reach `context`.
- Local plugins run in the host's Bun runtime, so `node:*` builtins are available (`node:fs`, `node:os`, `node:path`).

### Host-registered elements

The host registers OpenTUI renderables of its own at startup with `extend()` from
`@opentui/solid` — `extend({ spinner: SpinnerRenderable })`, for example.
A registered name becomes a JSX intrinsic process-wide, and a plugin's JSX
compiles to the host's `@opentui/solid` instance, so a host-contributed element
is usable with no import and no dependency:
`<spinner frames={frames} color={colorGenerator} interval={40} />`.

The inputs belong to the host element, not to a plugin API: `<spinner>` takes an
array of frame strings plus a per-cell color function, and the host element owns
the animation clock and the painting.
That division is the useful part — a plugin computes the frames and colors, the
host decides when they advance and how they are drawn.

Registering a name of your own would mean depending on `@opentui/solid` itself,
which local plugins deliberately do not do.
As with host command IDs, treat a host element's name and inputs as host
internals that can move between releases.

### Nodes, props, and geometry

- A node's props are applied when the node is created.
  Changing `fg`, `top`, or `left` on a node that already exists does not repaint it,
  so a colour or a position that changes needs a fresh node — a keyed `Show` around
  it, for example.
- `screenX`, `screenY`, `width` and `height` describe the last frame that was laid
  out, so a node created or moved in this frame still reports the terminal origin.
  Read a box from the renderer's `frame` event (`useRenderer().on("frame", …)`), not
  while rendering.
- The renderer emits `resize` after resizing its console and before it asks for the
  next frame, so an effect on `useTerminalDimensions()` sees the new size in time to
  re-place content before the host paints it.

## Slots

Placement keys, per-slot input props, and the published path list are upstream.
Three behaviours are only in the host source:

- `replace` takes over the target and suppresses its inner claims; an ancestor replacement beats a descendant one.
- At a path the host no longer publishes, additive claims degrade to the nearest
  surviving ancestor, and replacements are suppressed.
- `before` and `after` on `app` are no-ops: the root has no siblings.

Claims also have a lifetime, because the host mounts a session under a keyed `Show`
on its session id and switches routes beside the `app` claim:

- Switching session destroys the session subtree.
  A claim on a session slot, and every effect inside it, dies on the switch, so
  anything that must outlive a session belongs to the plugin scope rather than to the
  slot component.
- The `app` claim is a sibling of the route switch, so it survives session changes;
  it is where UI that reacts to the current route belongs.
  A route is the view the host is showing: the home screen, a session identified by
  its id, or a plugin page.
  `context.ui.router.current()` is reactive inside a Solid computation, so such a
  component tracks the route by reading it.
  Upstream does not state that.

See `overlay-slot-trick.md` for placing an element anywhere via the `app` slot.

## Keymap

Command fields, layer lifecycle, and the purity rule are upstream.
Two constraints cost us time and are collected in `pitfalls.md`:

- Creating a layer directly in `setup` can fail with `Keymap.Provider is missing`;
  creating it from an `app`-slot render works.
- An exception thrown inside a command's `run` handler is swallowed silently, so the bound key just does nothing.

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

## Input modes

`context.keymap.mode.push(name)` deactivates `base` layers while `global` layers keep running.
It isolates keymap layers only: the prompt's text input is not a layer, so typing
still lands in the composer behind a visible panel.
Do not rely on the mode to swallow typing.

## Surfaces

Panel, dialog, route, and toast APIs are upstream, including `ui.panel.open`
returning `false` outside a session route.
One host-side constraint is worth repeating: the host panel has a fixed size and
position, so a plugin can only offset its own content inside it.

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

