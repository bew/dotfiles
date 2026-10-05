# ui-tester plugin

Global OpenCode V2 TUI plugin: a playground for OpenCode UI slots and surfaces.

`/ui-tester` arms the plugin and shows a settings panel.
The panel is one component on two surfaces — docked (the host session panel) or
floating (an absolutely-positioned overlay) — and both draw camera-style corner
marks made of background-coloured cells.
Each widget prints the slot path it was placed into, so you can see how slots
compose and how each placement behaves.

## Command

`/ui-tester` runs immediately from the slash palette (no submit needed).

- `/ui-tester` — arm and show the panel, or hide it when already armed.
- To turn the plugin off, pick the `disarm` row in the panel; it removes the
  widgets and the indicator.

## Lifecycle

- `/ui-tester` arms the plugin and turns on the `alt+f` toggle.
- `alt+f` shows/hides the panel while armed.
- While armed but hidden, `prompt.footer.status` shows `UI-TESTER ARMED — ALT+F`
  in uppercase on a vivid background with dark text.
- The panel's `disarm` row removes the indicator and the widgets.

## Keybindings

All panel keys are `global` keymap commands, gated with `enabled`, so they are
inert unless the panel is shown (or, for the toggle, armed). While the text field
is focused only `alt+f`, `alt+i`, and `esc` stay active, so typing reaches the field.

- `alt+f` — show/hide the panel (while armed).
- `alt+i` — release/re-arm the pushed input mode (see below).
- `d` — switch between docked and floating.
- `p` — cycle the placement mode.
- `shift+d` — disarm: hide the panel and remove the widgets and indicator.
- `c` — cycle the background colour.
- `shift+c` — centre the floating panel.
- `h`/`j`/`k`/`l` — move the floating panel one cell; `shift` moves ten.
- `↑`/`↓` — move the settings cursor.
- `alt+j`/`alt+k` — move the settings cursor, whether docked or floating.
- `j`/`k` — move the settings cursor **when docked** (when floating they move the panel).
- `enter`/`space`/click — activate the focused row.
- `esc` — hide the panel.

## Panel rows

- `toggle all slots` — all on when none is on, otherwise all off.
- `placement` — cycles the active placement.
- `surface` — toggles docked/floating.
- `open page` — navigate to the plugin-registered route.
- `disarm` — hide the panel and remove the widgets and indicator.

## Input isolation

While the panel is shown it pushes an OpenCode input mode
(`context.keymap.mode.push("ui-tester")`).
Layers default to the `base` mode, so pushing this stops the prompt's typing
layers while leaving `global` layers (the host's own keys and this plugin's)
active — "block typing only".

`alt+i` releases the mode temporarily so the prompt can be used again;
`alt+i` again re-arms it.
The panel also has a text field, so you can type without touching the prompt.

## Slots

- `app`
- `home.footer`
- `home.footer.status`
- `prompt.footer`
- `prompt.footer.status`
- `prompt.footer.file`
- `session.composer.top`
- `session.panel`
- `sidebar.content`
- `sidebar.footer`

## Placements

- `append` / `prepend` — first/last inside the target boundary.
- `before` / `after` — siblings outside the target boundary.
- `replace` — takes over the target; the original content returns when the widget is removed.
  On `app` and `session.panel` it is downgraded to `before` instead (replace would hide the whole app or the panel content), and the widget says so.

## Surfaces and corners

- Docked: this plugin's `session.panel` contribution. Corner marks sit inside
  the panel area.
- Floating: an absolutely-positioned box claimed in the `app` slot (see
  `opencode/plugin-docs/overlay-slot-trick.md`). Corner marks sit at the four
  corners of the screen; the box moves with `h`/`j`/`k`/`l` and its position is a
  ratio of the movable range, so it stays proportional on resize
  (`useTerminalDimensions`).

Both surfaces share one background colour, cycled with `c` through a dark
palette; the corner marks use the matching bright palette so they stand out.

Caveats:

- The host panel cannot be moved or resized; only the floating box can.
- The floating box has a fixed footprint (`FLOAT_WIDTH` × `FLOAT_HEIGHT`), not
  fitted to its content.
- The bottom screen corners anchor to the bottom of the host main area (above its
  bottom bars), not the terminal's last row.
- `keymap.mode.push` is documented only as "mutually exclusive OpenCode input
  modes", so that it isolates exactly typing and nothing else is empirical.
- The corner marks are blocks of background colour, not box-drawing glyphs.

## Layout

Discovered automatically from the global plugins root (`~/.config/opencode/plugins/`).
`index.ts` is the server entry (no behavior); `tui.tsx` is the TUI entry.

## Notes

- Widgets use `context.theme.hue.accent[400]`, so they follow the active theme.
- `sidebar.*` slots are visible only when the sidebar is shown (`cli.json` hides it by default).
- `session.panel` renders only while this plugin's panel is docked and open.
- Panel state (arm, dock, colour, float position) is in-memory; it resets on plugin reload.
- The page (`/ui-tester page`) is a plugin route, not a host tab; `q` returns home.
