/** @jsxImportSource @opentui/solid */
// Global V2 TUI plugin: a playground for OpenCode UI slots and surfaces.
//
// `/ui-tester` arms the plugin: it shows a settings panel and turns on the
// `alt+f` toggle.
// `alt+f` shows/hides the panel, `/ui-tester off` disarms it.
// While armed but hidden, an indicator in the prompt footer says how to bring
// it back, and the rest of OpenCode behaves normally.
//
// The settings UI is one component rendered on two surfaces:
//   - docked: this plugin's contribution to the host session panel
//   - floating: an absolutely-positioned box in the `app` slot overlay
//     (see opencode/plugin-docs/overlay-slot-trick.md)
// Both draw camera-style corner marks made of background-coloured cells:
// docked inside its own panel area, floating at the four corners of the screen.
// The floating panel moves with h/j/k/l (shift steps ten cells) and its
// position is stored as a ratio so it survives terminal resizes.
//
// While the panel is shown it pushes an OpenCode input mode, which stops the
// prompt from receiving typing without disabling the host's global keys.
// `alt+i` temporarily releases that mode; the panel also has a text field.
//
// Each slot widget names the slot it was placed into, so placement modes and
// slot composition are visible directly.
//
// The `@jsxImportSource` pragma pins the JSX runtime to `@opentui/solid`, so the
// file compiles the same whether or not the loader configures it.

import { Plugin, usePlugin } from "@opencode/plugin/tui";
import type { Context, PanelInput, PanelPresentation, SlotPath } from "@opencode/plugin/tui/context";
import { useTerminalDimensions } from "@opentui/solid";
import { createEffect, createSignal, For, onCleanup, Show } from "solid-js";

// Every UI slot the host publishes, enumerated for the widgets and the panel.
const SLOT_PATHS = [
  "app",
  "home.footer",
  "home.footer.status",
  "prompt.footer",
  "prompt.footer.status",
  "prompt.footer.file",
  "session.composer.top",
  "session.panel",
  "sidebar.content",
  "sidebar.footer",
] as const satisfies readonly SlotPath[];

// Where a widget attaches to a slot, matching OpenCode's five placement keys.
type Placement = "append" | "prepend" | "before" | "after" | "replace";

// Valid `Placement` values, ordered for display.
const PLACEMENTS: readonly Placement[] = ["append", "prepend", "before", "after", "replace"];

// Slots where `replace` would hide something the tester itself needs.
// Returns the reason `replace` is refused, or `undefined` when it is allowed.
// `app` takes over the whole application root and `session.panel` the docked
// settings panel, so a replace widget there would blank the UI or its own controls.
function replaceSkipReason(path: SlotPath): string | undefined {
  if (path === "app") {
    return "replace skipped — it would hide the whole app";
  }
  if (path === "session.panel") {
    return "replace skipped — it would hide the panel content";
  }
  return undefined;
}

// Input mode pushed while the panel is shown.
// Layers default to the `base` mode, so pushing this stops the prompt's typing
// layers while leaving `global` layers (the host's own keys and ours) active.
const MODE_NAME = "ui-tester";

// Content name for this plugin's session-panel contribution.
const PANEL_NAME = "ui-tester.panel";

// Route name for the plugin-registered page.
const PAGE_NAME = "ui-tester.page";

// Cells between the floating panel's content and its border.
const FLOAT_PADDING = 2;

// Floating panel footprint, in cells.
// Fixed so the move maths stays simple.
const FLOAT_WIDTH = 50;
const FLOAT_HEIGHT = 26;

// Camera-corner mark size, in cells: each mark is an L of background-coloured
// cells — a bar along the edge and a bar down it — not a box-drawing glyph.
const CORNER_WIDTH = 12;
const CORNER_HEIGHT = 5;
const CORNER_THICK = 1;

// Dark background palette cycled with `c`.
// All are low-luminance so the text stays readable; the first is the default.
const PANEL_COLORS: readonly string[] = ["#0b2b1f", "#0a2f33", "#101b3a", "#241038"];

// Footer indicator colours: a vivid green background with near-black text, so
// the armed state is impossible to miss.
const INDICATOR_BACKGROUND = "#3ddc84";
const INDICATOR_TEXT = "#04120b";

// Bright counterparts of PANEL_COLORS (same order), used for the corner marks
// so they stay visible against the dark panel area.
const CORNER_COLORS: readonly string[] = ["#3ddc84", "#2fd6d6", "#4d8dff", "#b06bff"];

// Every row the settings panel renders: the all-slots toggle, the placement
// cycler, the dock toggle, the page launcher, and the disarm row.
type PanelRow = "all" | "placement" | "dock" | "page" | "disarm";

// Panel rows in display order.
const PANEL_ROWS: readonly PanelRow[] = ["all", "placement", "dock", "page", "disarm"];

// Bright debug label naming the slot a widget was placed into.
// The composer-top slot renders a horizontal strip instead, to show a custom
// "bar" layout.
function SlotWidget(props: { path: SlotPath; note?: string }) {
  const context = usePlugin();
  if (props.path === "session.composer.top") {
    return (
      <box flexDirection="row">
        <text fg={context.theme.hue.accent[400]}>ui-tester:session.composer.top</text>
        <text fg={context.theme.text.muted}>{"  │  "}</text>
        <text fg={context.theme.hue.accent[400]}>[tab-a]</text>
        <text fg={context.theme.text.muted}>{"  "}</text>
        <text fg={context.theme.hue.accent[400]}>[tab-b]</text>
      </box>
    );
  }
  return (
    <box flexDirection="row">
      <text fg={context.theme.hue.accent[400]}>ui-tester:{props.path}</text>
      <Show when={props.note}>
        <text fg={context.theme.text.default}>{` — ${props.note}`}</text>
      </Show>
    </box>
  );
}

// Camera-style corner marks: at each corner of the nearest positioned ancestor,
// a horizontal bar along the edge and a vertical bar down it, painted as
// background-coloured cells.
// The app slot's host box and the panel's own box are both `position: relative`,
// so the same component frames the screen (floating) or the panel area (docked).
function CameraCorners(props: { color: string }) {
  return (
    <>
      <box
        position="absolute"
        top={0}
        left={0}
        width={CORNER_WIDTH}
        height={CORNER_THICK}
        backgroundColor={props.color}
      />
      <box
        position="absolute"
        top={0}
        left={0}
        width={CORNER_THICK}
        height={CORNER_HEIGHT}
        backgroundColor={props.color}
      />
      <box
        position="absolute"
        top={0}
        right={0}
        width={CORNER_WIDTH}
        height={CORNER_THICK}
        backgroundColor={props.color}
      />
      <box
        position="absolute"
        top={0}
        right={0}
        width={CORNER_THICK}
        height={CORNER_HEIGHT}
        backgroundColor={props.color}
      />
      <box
        position="absolute"
        bottom={0}
        left={0}
        width={CORNER_WIDTH}
        height={CORNER_THICK}
        backgroundColor={props.color}
      />
      <box
        position="absolute"
        bottom={0}
        left={0}
        width={CORNER_THICK}
        height={CORNER_HEIGHT}
        backgroundColor={props.color}
      />
      <box
        position="absolute"
        bottom={0}
        right={0}
        width={CORNER_WIDTH}
        height={CORNER_THICK}
        backgroundColor={props.color}
      />
      <box
        position="absolute"
        bottom={0}
        right={0}
        width={CORNER_THICK}
        height={CORNER_HEIGHT}
        backgroundColor={props.color}
      />
    </>
  );
}

// Body of the plugin-registered route (an own page, not a host tab).
// With the page shown, its keymap layer is active: q returns home.
function PageBody() {
  const context = usePlugin();
  context.keymap.layer(() => ({
    commands: [
      {
        id: "ui-tester.page.home",
        bind: "q",
        run: () => context.ui.router.navigate({ type: "home" }),
      },
    ],
  }));
  return (
    <box flexDirection="column">
      <text fg={context.theme.hue.accent[400]}>ui-tester:page</text>
      <text fg={context.theme.text.muted}>A plugin-registered route — an own page, not a host tab.</text>
      <text fg={context.theme.text.muted}>q back home</text>
    </box>
  );
}

// Props for the settings panel.
// The panel is presentational: the owning surface (docked contribution or
// floating box) and the app-slot key layer drive it.
type SettingsPanelProps = {
  placement: Placement;
  allSlotsEnabled: boolean;
  docked: boolean;
  color: string;
  cornerColor: string;
  corners: boolean;
  cursor: number;
  onActivate: (row: PanelRow) => void;
  onCursor: (index: number) => void;
  onTextFocus: (focused: boolean) => void;
};

// Label for a row, including its checked marker where it has one.
function rowLabel(props: SettingsPanelProps, row: PanelRow): string {
  switch (row) {
    case "all":
      return `${props.allSlotsEnabled ? "[x]" : "[ ]"} toggle all slots`;
    case "placement":
      return `placement: ${props.placement} — enter to cycle`;
    case "dock":
      return `surface: ${props.docked ? "docked" : "floating"} — enter to toggle`;
    case "page":
      return "open page";
    case "disarm":
      return "disarm — remove the UI tester";
  }
}

// The settings UI, shared by both surfaces.
// It fills its parent, paints the cycled background colour behind the text only
// (so the surrounding area stays dark and the corner marks contrast), and
// optionally frames itself with corner marks.
// Keys are handled by the app-slot layer; rows respond to clicks only.
function SettingsPanel(props: SettingsPanelProps) {
  const context = usePlugin();
  return (
    <box
      position="relative"
      width="100%"
      height="100%"
      flexDirection="column"
      justifyContent="center"
      alignItems="center"
    >
      <Show when={props.corners}>
        <CameraCorners color={props.cornerColor} />
      </Show>
      <box backgroundColor={props.color} flexDirection="column" alignItems="center" padding={1}>
        <text fg={context.theme.text.muted}>ui-tester — {props.docked ? "docked" : "floating"}</text>
        <text fg={context.theme.text.muted}>↑/↓ or alt+j/alt+k move · enter/click toggle</text>
        <text fg={context.theme.text.muted}>c colour · shift+c centre · d dock</text>
        <text fg={context.theme.text.muted}>p placement · shift+d disarm</text>
        <text fg={context.theme.text.muted}>alt+i release · esc hide</text>
        <text>{" "}</text>
        <For each={PANEL_ROWS}>
          {(row, index) => (
            <text
              fg={props.cursor === index() ? context.theme.hue.accent[400] : context.theme.text.base}
              selectable={false}
              onMouseDown={() => {
                props.onCursor(index());
                props.onActivate(row);
              }}
            >
              {rowLabel(props, row)}
            </text>
          )}
        </For>
        <text>{" "}</text>
        <input
          placeholder="type here (ui-tester)"
          width={32}
          onFocus={() => props.onTextFocus(true)}
          onBlur={() => props.onTextFocus(false)}
        />
      </box>
    </box>
  );
}

// Attach a widget to `path` with `placement`; returns the slot's disposer.
// `note` appends an explanatory message to the widget label.
function claim(
  context: Context,
  path: SlotPath,
  placement: Placement,
  note?: string,
): () => void {
  const render = () => <SlotWidget path={path} note={note} />;
  switch (placement) {
    case "append":
      return context.ui.slot({ append: path, render });
    case "prepend":
      return context.ui.slot({ prepend: path, render });
    case "before":
      return context.ui.slot({ before: path, render });
    case "after":
      return context.ui.slot({ after: path, render });
    case "replace":
      return context.ui.slot({ replace: path, render });
  }
}

export default Plugin.define({
  id: "ui-tester.tui",
  setup(context) {
    // Live plugin state.
    // Widgets: which slots have one and at which placement.
    // Panel: whether the plugin is armed, shown, docked, released, and which
    // colour index, cursor row, and float position are active.
    const [enabledSlots, setEnabledSlots] = createSignal<ReadonlySet<SlotPath>>(new Set());
    const [placement, setPlacement] = createSignal<Placement>("append");
    const [armed, setArmed] = createSignal(false);
    const [visible, setVisible] = createSignal(false);
    const [docked, setDocked] = createSignal(false);
    const [released, setReleased] = createSignal(false);
    const [colorIndex, setColorIndex] = createSignal(0);
    const [cursor, setCursor] = createSignal(0);
    const [textFocused, setTextFocused] = createSignal(false);
    const [floatX, setFloatX] = createSignal(0.5);
    const [floatY, setFloatY] = createSignal(0.35);
    const [panelPresentation] = createSignal<PanelPresentation>("panel");
    // Widget disposers, cleared on each re-sync and on plugin teardown.
    const widgetDisposers = new Set<() => void>();

    // Contribution disposers, torn down only when the plugin deactivates.
    const setupDisposers = new Set<() => void>();

    // Route disposers, registered once from the app-slot surface.
    const routeDisposers = new Set<() => void>();

    // Active panel background colour, from the cycled palette.
    const panelColor = () => PANEL_COLORS[colorIndex()] ?? "#0b2b1f";

    // Active corner-mark colour, from the bright palette at the same index.
    const cornerColor = () => CORNER_COLORS[colorIndex()] ?? "#3ddc84";

    // Detach every widget currently attached.
    function remove() {
      for (const dispose of widgetDisposers) dispose();
      widgetDisposers.clear();
    }

    // Attach a widget for every enabled slot at the active placement.
    function syncSlots() {
      remove();
      const activePlacement = placement();
      const enabled = enabledSlots();
      for (const path of SLOT_PATHS) {
        if (!enabled.has(path)) {
          continue;
        }
        const skipReason = activePlacement === "replace" ? replaceSkipReason(path) : undefined;
        // Downgrade to `before` rather than skip, so the widget still shows and
        // explains why `replace` was refused.
        if (skipReason !== undefined) {
          widgetDisposers.add(claim(context, path, "before", skipReason));
          continue;
        }
        widgetDisposers.add(claim(context, path, activePlacement));
      }
    }

    // Toggle every slot: all off when any is on, otherwise all on.
    function toggleAllSlots() {
      setEnabledSlots((previous) => (previous.size > 0 ? new Set() : new Set(SLOT_PATHS)));
      syncSlots();
    }

    // Advance to the next placement mode and re-sync the attached widgets.
    function cyclePlacement() {
      setPlacement((previous) => {
        const next = (PLACEMENTS.indexOf(previous) + 1) % PLACEMENTS.length;
        return PLACEMENTS[next] ?? "append";
      });
      syncSlots();
    }

    // Detach every widget, clear the enabled set, and report it.
    function disableAll() {
      setEnabledSlots(new Set());
      syncSlots();
      context.ui.toast.show({ message: "ui-tester: widgets off" });
    }

    // Arm the plugin and show the panel on the requested surface.
    function show(nextDocked: boolean) {
      setArmed(true);
      setVisible(true);
      setDocked(nextDocked);
      setReleased(false);
      setTextFocused(false);
    }

    // Disarm the plugin: hide the panel and the indicator.
    function disarm() {
      setArmed(false);
      setVisible(false);
      setDocked(false);
      setReleased(false);
      setTextFocused(false);
    }

    // Show/hide the panel while armed; hides the mode release with it.
    function toggleVisible() {
      if (!armed()) {
        return;
      }
      const next = !visible();
      if (!next) {
        setReleased(false);
        setTextFocused(false);
      }
      setVisible(next);
    }

    // Switch the shown panel between docked and floating.
    function toggleDock() {
      setDocked((previous) => !previous);
      setTextFocused(false);
    }

    // Advance to the next background colour.
    function cycleColor() {
      setColorIndex((previous) => (previous + 1) % PANEL_COLORS.length);
    }

    // Release or re-arm the input mode so the prompt can be used again.
    function toggleRelease() {
      setReleased((previous) => !previous);
    }

    // Move the settings cursor by `delta` rows, wrapping.
    function moveCursor(delta: number) {
      setCursor((index) => (index + delta + PANEL_ROWS.length) % PANEL_ROWS.length);
    }

    // Run the action for a row.
    function activate(row: PanelRow) {
      switch (row) {
        case "all":
          toggleAllSlots();
          return;
        case "placement":
          cyclePlacement();
          return;
        case "dock":
          toggleDock();
          return;
        case "page":
          context.ui.router.navigate({ type: "plugin", name: PAGE_NAME });
          return;
        case "disarm":
          disarm();
          disableAll();
          return;
      }
    }

    // Run the action for the currently focused row.
    function activateFocused() {
      const row = PANEL_ROWS[cursor()];
      if (row !== undefined) {
        activate(row);
      }
    }

    // Register the `/ui-tester` command; runs inside the host's keymap provider.
    function registerCommands() {
      context.keymap.layer(() => ({
        mode: "global",
        priority: 10,
        commands: [
          // No `arguments`, so picking this from the slash palette runs it
          // immediately (like the built-in commands) rather than leaving the
          // name in the prompt to submit.
          {
            id: "ui-tester.show",
            title: "UI tester: show/hide panel",
            group: "UI tester",
            palette: true,
            slash: { name: "ui-tester" },
            run: () => (armed() ? toggleVisible() : show(false)),
          },
        ],
      }));
    }

    // Always-mounted app-slot surface: owns the panel keys, the pushed input
    // mode, the docked-panel lifecycle, and the floating overlay.
    // A keymap layer must be created inside a reactive scope the host mounts
    // under its `Keymap.Provider`; calling it in `setup()` throws
    // "Keymap.Provider is missing", so everything lives here.
    function AppSurface() {
      const dimensions = useTerminalDimensions();

      registerCommands();
      routeDisposers.add(
        context.ui.router.register({ name: PAGE_NAME, render: () => <PageBody /> }),
      );

      // Keep the host panel open exactly while the panel is docked and shown.
      createEffect(() => {
        if (visible() && docked()) {
          context.ui.panel.open(PANEL_NAME, { presentation: panelPresentation() });
          return;
        }
        context.ui.panel.close();
      });

      // Push an exclusive input mode while the panel is shown, so the prompt
      // stops receiving typing; `alt+i` releases it temporarily.
      createEffect(() => {
        if (!visible() || released()) {
          return;
        }
        const pop = context.keymap.mode.push(MODE_NAME);
        onCleanup(pop);
      });

      // Move the floating panel by `dx`/`dy` cells, as a ratio of its range.
      function step(dx: number, dy: number) {
        const rowsFree = Math.max(1, dimensions().height - FLOAT_HEIGHT);
        const colsFree = Math.max(1, dimensions().width - FLOAT_WIDTH);
        setFloatX((value) => Math.min(1, Math.max(0, value + dx / colsFree)));
        setFloatY((value) => Math.min(1, Math.max(0, value + dy / rowsFree)));
      }

      // Snap the floating panel back to the centre of the screen.
      function centerFloat() {
        setFloatX(0.5);
        setFloatY(0.5);
      }

      // Panel keys live in two layers.
      // The toggle, the release, and escape stay `global` so they work in every
      // mode; everything else is scoped to the pushed `ui-tester` mode, so
      // releasing the mode hands the keys back to the prompt.
      // The rest is also gated by `!textFocused()`, so typing reaches the text
      // field instead of being swallowed as a command.
      context.keymap.layer(() => ({
        mode: "global",
        priority: 20,
        commands: [
          {
            id: "ui-tester.toggle",
            bind: "alt+f",
            enabled: () => armed(),
            run: () => toggleVisible(),
          },
          {
            id: "ui-tester.release",
            bind: "alt+i",
            enabled: () => visible(),
            run: () => toggleRelease(),
          },
          {
            id: "ui-tester.hide",
            bind: "escape",
            enabled: () => visible(),
            run: () => toggleVisible(),
          },
        ],
      }));

      context.keymap.layer(() => ({
        mode: MODE_NAME,
        priority: 20,
        commands: [
          {
            id: "ui-tester.dock",
            bind: "d",
            enabled: () => visible() && !textFocused(),
            run: () => toggleDock(),
          },
          {
            id: "ui-tester.placement",
            bind: "p",
            enabled: () => visible() && !textFocused(),
            run: () => cyclePlacement(),
          },
          {
            id: "ui-tester.disarm",
            bind: "shift+d",
            enabled: () => visible() && !textFocused(),
            run: () => activate("disarm"),
          },
          {
            id: "ui-tester.color",
            bind: "c",
            enabled: () => visible() && !textFocused(),
            run: () => cycleColor(),
          },
          {
            id: "ui-tester.center",
            bind: "shift+c",
            enabled: () => visible() && !docked() && !textFocused(),
            run: () => centerFloat(),
          },
          {
            id: "ui-tester.cursor.up.alt",
            bind: "alt+k",
            enabled: () => visible() && !textFocused(),
            run: () => moveCursor(-1),
          },
          {
            id: "ui-tester.cursor.down.alt",
            bind: "alt+j",
            enabled: () => visible() && !textFocused(),
            run: () => moveCursor(1),
          },
          {
            id: "ui-tester.cursor.up",
            bind: "up",
            enabled: () => visible() && !textFocused(),
            run: () => moveCursor(-1),
          },
          {
            id: "ui-tester.cursor.down",
            bind: "down",
            enabled: () => visible() && !textFocused(),
            run: () => moveCursor(1),
          },
          {
            id: "ui-tester.cursor.up2",
            bind: "k",
            enabled: () => visible() && docked() && !textFocused(),
            run: () => moveCursor(-1),
          },
          {
            id: "ui-tester.cursor.down2",
            bind: "j",
            enabled: () => visible() && docked() && !textFocused(),
            run: () => moveCursor(1),
          },
          {
            id: "ui-tester.activate",
            bind: "enter",
            enabled: () => visible() && !textFocused(),
            run: () => activateFocused(),
          },
          {
            id: "ui-tester.activate2",
            bind: "space",
            enabled: () => visible() && !textFocused(),
            run: () => activateFocused(),
          },
          {
            id: "ui-tester.move.left",
            bind: "h",
            enabled: () => visible() && !docked() && !textFocused(),
            run: () => step(-1, 0),
          },
          {
            id: "ui-tester.move.down",
            bind: "j",
            enabled: () => visible() && !docked() && !textFocused(),
            run: () => step(0, 1),
          },
          {
            id: "ui-tester.move.up",
            bind: "k",
            enabled: () => visible() && !docked() && !textFocused(),
            run: () => step(0, -1),
          },
          {
            id: "ui-tester.move.right",
            bind: "l",
            enabled: () => visible() && !docked() && !textFocused(),
            run: () => step(1, 0),
          },
          {
            id: "ui-tester.move.left10",
            bind: "shift+h",
            enabled: () => visible() && !docked() && !textFocused(),
            run: () => step(-10, 0),
          },
          {
            id: "ui-tester.move.down10",
            bind: "shift+j",
            enabled: () => visible() && !docked() && !textFocused(),
            run: () => step(0, 10),
          },
          {
            id: "ui-tester.move.up10",
            bind: "shift+k",
            enabled: () => visible() && !docked() && !textFocused(),
            run: () => step(0, -10),
          },
          {
            id: "ui-tester.move.right10",
            bind: "shift+l",
            enabled: () => visible() && !docked() && !textFocused(),
            run: () => step(10, 0),
          },
        ],
      }));

      return (
        <Show when={visible() && !docked()}>
          <box
            position="absolute"
            top={Math.round(floatY() * Math.max(0, dimensions().height - FLOAT_HEIGHT))}
            left={Math.round(floatX() * Math.max(0, dimensions().width - FLOAT_WIDTH))}
            zIndex={5000}
            border
            padding={FLOAT_PADDING}
            width={FLOAT_WIDTH}
            height={FLOAT_HEIGHT}
            backgroundColor={panelColor()}
          >
            <SettingsPanel
              placement={placement()}
              allSlotsEnabled={enabledSlots().size > 0}
              docked={false}
              color={panelColor()}
              cornerColor={cornerColor()}
              corners={false}
              cursor={cursor()}
              onActivate={activate}
              onCursor={setCursor}
              onTextFocus={setTextFocused}
            />
          </box>
          <CameraCorners color={cornerColor()} />
        </Show>
      );
    }

    // Docked surface: the same settings panel, framed by its own corner marks.
    setupDisposers.add(
      context.ui.slot({
        append: "session.panel",
        render: (input: PanelInput) => {
          if (input.name !== PANEL_NAME) {
            return null;
          }
          return (
            <SettingsPanel
              placement={placement()}
              allSlotsEnabled={enabledSlots().size > 0}
              docked={true}
              color={panelColor()}
              cornerColor={cornerColor()}
              corners={true}
              cursor={cursor()}
              onActivate={activate}
              onCursor={setCursor}
              onTextFocus={setTextFocused}
            />
          );
        },
      }),
    );

    // Armed-but-hidden indicator, so the toggle is discoverable.
    setupDisposers.add(
      context.ui.slot({
        append: "prompt.footer.status",
        render: () =>
          armed() && !visible() ? (
            <box backgroundColor={INDICATOR_BACKGROUND}>
              <text fg={INDICATOR_TEXT}>{"UI-TESTER ARMED — ALT+F"}</text>
            </box>
          ) : null,
      }),
    );

    context.ui.slot({ append: "app", render: () => <AppSurface /> });

    return () => {
      remove();
      for (const dispose of setupDisposers) dispose();
      for (const dispose of routeDisposers) dispose();
    };
  },
});
