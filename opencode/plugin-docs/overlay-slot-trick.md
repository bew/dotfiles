# The `app`-slot overlay trick

OpenCode V2's TUI plugin API only lets a plugin render into a fixed set of named slots.
To place an arbitrary UI element anywhere on the screen instead, claim the `app` root slot and render an absolutely-positioned box.

## Why it works

The `app` slot renders inside the host's main-area box (`packages/tui/src/app.tsx`), which is `position="relative"`.
An absolutely-positioned descendant therefore resolves against that box, not against the slot's own zero-height boundary.
The main-area box starts at the top of the screen, so absolute `top`/`left` map to screen coordinates.
It spans the whole region above the host's bottom bars (devtools, reconnect, toasts), which are drawn outside it.

## Placing the element

Get the terminal size from `useTerminalDimensions`, imported from `@opentui/solid`.

```tsx
import { useTerminalDimensions } from "@opentui/solid";

const dimensions = useTerminalDimensions();
<box position="absolute" top={...} left={...} zIndex={5000}>…</box>
```

`top`/`left` are cell offsets from the box's top-left corner.
The `bottom`/`right` props anchor to the opposite edges, which is steadier when the host content shifts.
Pick a `zIndex` above the host's overlays — the prompt's autocomplete uses `100`, the diff viewer `2500`, the startup overlay `5000` — so the element stays on top.
Give the element an explicit size when its contents would not size it, or the positioning math will drift.

## Clicking it

OpenTUI synthesises no `click` event — a click is a `down` and an `up`.
The host's own clickable elements listen on `onMouseUp`, guard the left button, and stop propagation:

```tsx
onMouseUp={(event) => {
  if (event.button !== 0) return;
  event.stopPropagation();
  open();
}}
```

`stopPropagation` matters: without it the event also reaches the surface beneath the overlay.

## Caveats

- This is a coordinate hack, not a slot; any host layout change can shift the element.
- It breaks on resize unless coordinates come from `useTerminalDimensions`.
- It is easy to cover or block other UI, since the overlay sits on top of everything.
- It is neither discoverable nor supported by the host; the slot API may change under it.
