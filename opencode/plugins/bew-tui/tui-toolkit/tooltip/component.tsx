/** @jsxImportSource @opentui/solid */
// Tooltip overlay: a small panel of capped rows, placed beside the element
// its caller points at.
//
// The caller owns the visibility (see `when`) and renders this in a slot that
// allows absolute positioning: the `app` slot's box is the whole main area.

import { usePlugin } from "@opencode/plugin/tui";
import { useRenderer, useTerminalDimensions } from "@opentui/solid";
import type { MouseEvent } from "@opentui/core";
import {
  For,
  children,
  createEffect,
  createMemo,
  createSignal,
  on,
  onCleanup,
  Show,
} from "solid-js";
import type { JSX } from "solid-js";
import {
  TOOLTIP_LEFT_MARGIN,
  TOOLTIP_RIGHT_MARGIN,
  resolveTooltipPosition,
} from "./layout";
import { rectOf } from "./anchor";
import type { AnchorRef } from "./anchor";
import { PLACEHOLDER_ROWS, placeholderWidth } from "./placeholder";

// Cells the panel pads its body by on each side.
// The panel owns this padding, so a caller only deals in
// the cells its rows get.
const BODY_PADDING_X = 1;

// Rows taken by the two half-block cap rows.
const CAP_ROWS = 2;

// Rows the header band takes when the tooltip has a title or a close control.
const HEADER_ROWS = 1;

// Glyph of the close control, drawn at the right end of the header band.
const CLOSE_GLYPH = "✕";

// Half-block glyph row that caps the top edge, filled on its lower half so the
// band meets the content below.
const TOP_CAP = "▄";

// Half-block glyph row that caps the bottom edge, filled on its upper half so
// the band meets the content above.
const BOTTOM_CAP = "▀";

// Spaces that pad the title text inside its inverted band, on each side.
const TITLE_PADDING = "   ";

// Renderer event emitted once a frame has been laid out and presented.
// A renderable's box is only trustworthy from then on.
const RENDER_FRAME_EVENT = "frame";

// Minimum time between two panel rebuilds while the anchor keeps
// moving, in milliseconds.
// A rebuild is what moves the panel, so this caps how often a burst of layout
// changes recreates it.
const REBUILD_INTERVAL_MS = 20;

// What the body builder returns: the content the panel draws, the cells it
// needs, and how many rows it takes.
export type TooltipBody = {
  // Cells the content needs, padding excluded; the panel adds its padding and
  // narrows this to the cells it may take.
  readonly width: number;
  // Heading for the panel's header band, drawn centred above the content.
  readonly title?: string;
  // Rows the content occupies; the panel adds its own cap and title rows.
  readonly bodyRows: number;
  // The content itself, drawn on the panel background.
  readonly content: JSX.Element;
};

// Everything the tooltip needs to render.
export type TooltipProps = {
  // Whether the panel is drawn at all.
  // A caller that keeps its state while the panel is off screen hides it here
  // rather than unmounting it.
  // Neither the anchor nor the body is read while hidden.
  readonly when?: boolean;
  // Ref for the element the tooltip points at.
  // Its box is read from the renderer's frames, so the panel follows that
  // element when the layout moves it, and a ref yielding no box
  // leaves the panel undrawn.
  readonly anchorRef: AnchorRef;
  // Widest body the caller wants, in cells, padding excluded: the panel adds
  // its own padding and shrinks the body to the width the terminal
  // leaves, never widening it.
  readonly preferredBodyWidth: number;
  // Builds what the panel draws, given the cells its body may use against the
  // current terminal; the returned width is the content's own, so the caller
  // never does the panel's padding arithmetic.
  // Called again whenever that width changes, so content can wrap to the panel
  // rather than past it.
  // Returning nothing shows the panel's placeholder instead.
  readonly body: (contentWidth: number) => TooltipBody | undefined;
  // Called when the close glyph is clicked.
  // A tooltip without it cannot be dismissed from the panel itself and
  // shows no close control.
  readonly onClose?: () => void;
};

// The panel's box as decided for one placement: a rebuild draws the panel at
// these coordinates and this size.
type PanelPlacement = {
  readonly top: number;
  readonly left: number;
  readonly width: number;
  readonly height: number;
};

// The tooltip panel: half-block caps around a filled body, placed near the
// element its ref points at.
//
// The panel goes above the anchor when it fits, below it otherwise, and is
// centred on the anchor while staying inside the terminal margins.
//
// The anchor is sampled from the renderer's frame events, since a renderable
// that was just mounted or moved still reports the terminal origin until the
// next frame has been laid out.
// The panel therefore appears on the frame after it mounts.
//
// Moving the panel means rebuilding it, so consecutive moves are rate limited:
// the panel follows a resize roughly, and lands once the anchor settles.
//
// A terminal resize places the panel again before the frame that lays the new
// size out, so it is never painted against the screen it used to fit.
//
// The panel sizes itself: the body builder states the cells its content needs
// and how many rows it takes.
// The frame adds its own padding, cap and title rows, all held inside the cells
// the caller and the terminal leave.
//
// A panel taller than the terminal is cut to the terminal height,
// and its body scrolls.
export function Tooltip(props: TooltipProps) {
  const context = usePlugin();
  const renderer = useRenderer();
  const viewport = useTerminalDimensions();

  // Whether the caller wants a panel on screen; a hidden panel is not laid out,
  // so nothing reads the anchor or builds a body.
  const shown = () => props.when !== false;

  // Cells the panel may take inside the terminal margins, its padding included.
  const maxPanelWidth = createMemo(() =>
    Math.max(1, viewport().width - TOOLTIP_LEFT_MARGIN - TOOLTIP_RIGHT_MARGIN),
  );

  // Cells the body rows may use: the caller's preference, held inside what the
  // terminal leaves once the panel has paid for its padding.
  const contentLimit = createMemo(() =>
    Math.max(
      1,
      Math.min(props.preferredBodyWidth, maxPanelWidth() - 2 * BODY_PADDING_X),
    ),
  );

  // What the panel draws, built for the cells the body may use, so rows wrap to
  // the panel instead of running past it.
  // A caller with nothing to show gets the placeholder, which is a body of its
  // own so sizing stays uniform.
  const bodyView = createMemo(
    () => props.body(contentLimit()) ?? placeholderBody(contentLimit()),
  );

  // Panel width in cells: the content's width plus the padding, held inside the
  // cells the terminal leaves, so a row of it cannot run past the right edge.
  const panelWidth = createMemo(() =>
    Math.min(
      maxPanelWidth(),
      Math.max(1, bodyView().width) + 2 * BODY_PADDING_X,
    ),
  );
  const hasHeader = () =>
    bodyView().title !== undefined || props.onClose !== undefined;

  // The panel's own size, recomputed when its body or the terminal changes, so
  // a tooltip that replaces another does not keep the earlier height.
  //
  // A panel taller than the terminal is cut to the terminal height, and its
  // body scrolls, so its rows never run off the screen.
  const layout = createMemo(() => {
    const frameRows = CAP_ROWS + (hasHeader() ? HEADER_ROWS : 0);
    const maxRows = Math.max(frameRows + 2, viewport().height);
    const fullHeight = frameRows + bodyView().bodyRows;
    const height = Math.min(fullHeight, maxRows);
    // Rows the body shows at once; the rest stay reachable by scrolling.
    return { height, bodyRows: height - frameRows };
  });

  // Fill colour of the tooltip body.
  const panelColor = context.theme.hue.gray[600];

  // The body content, resolved once so it survives the panel rebuilds a move
  // causes: the same nodes are re-inserted rather than created afresh.
  const body = children(() => bodyView().content);

  // The caps carry no background: the half-block glyph is drawn in the panel
  // colour and the half it leaves free shows the terminal background.

  // Where the panel belongs and how big it is, from the anchored element's box
  // as of the current layout; nothing while that box is unavailable.
  const measurePlacement = (): PanelPlacement | undefined => {
    if (!shown()) {
      return undefined;
    }
    const box = props.anchorRef();
    if (box === undefined) {
      return undefined;
    }
    const size = { width: panelWidth(), height: layout().height };
    const at = resolveTooltipPosition(rectOf(box), size, viewport());
    return {
      top: at.top,
      left: at.left,
      width: size.width,
      height: size.height,
    };
  };

  // Whether, and where, the panel is drawn; undefined until the anchor has a
  // laid-out box, or once it is gone.
  const [placement, setPlacement] = createSignal<PanelPlacement>();

  // When the panel was last rebuilt, and the pending rebuild a burst delayed.
  // Both are plain locals: they are bookkeeping the panel never renders from.
  let rebuiltAt = 0;
  let settleTimer: ReturnType<typeof setTimeout> | undefined;

  // Places the panel unless the placement would rebuild it for the same box.
  const applyPlacement = (at: PanelPlacement | undefined): void => {
    const previous = placement();
    // The size counts too: a narrower terminal gives the panel a narrower box,
    // and the cap rows are drawn once, when the panel is created.
    if (
      previous?.top === at?.top &&
      previous?.left === at?.left &&
      previous?.width === at?.width &&
      previous?.height === at?.height
    ) {
      return;
    }
    setPlacement(() => at);
    rebuiltAt = performance.now();
  };

  // Applies the placement a frame held back, measured again so it uses the
  // geometry the anchor has by the time it runs.
  const flushPlacement = (): void => {
    settleTimer = undefined;
    applyPlacement(measurePlacement());
  };

  // Follows the anchor across frames, rate limiting the rebuilds that follow.
  const onFrame = (): void => {
    const at = measurePlacement();
    // The first placement and the removal of the panel skip the interval: there
    // is no panel on screen for a rebuild to disturb.
    if (at === undefined || placement() === undefined) {
      applyPlacement(at);
      return;
    }
    const elapsed = performance.now() - rebuiltAt;
    if (elapsed >= REBUILD_INTERVAL_MS) {
      applyPlacement(at);
      return;
    }
    // One timer at a time: later frames refresh the measured anchor, not the
    // deadline, so a long resize still rebuilds about once per interval.
    if (settleTimer === undefined) {
      settleTimer = setTimeout(flushPlacement, REBUILD_INTERVAL_MS - elapsed);
    }
  };

  renderer.on(RENDER_FRAME_EVENT, onFrame);
  onCleanup(() => {
    renderer.off(RENDER_FRAME_EVENT, onFrame);
    if (settleTimer !== undefined) {
      clearTimeout(settleTimer);
    }
  });

  // Drops the placement while the caller hides the panel, so showing it again
  // measures the anchor afresh instead of flashing at the old spot.
  //
  // Deferred because the first run would only drop a panel the frame
  // handler has not placed yet.
  createEffect(
    on(
      shown,
      (isShown) => {
        if (!isShown) {
          applyPlacement(undefined);
        }
      },
      { defer: true },
    ),
  );

  // Re-place the panel as soon as the terminal changes size, before the frame
  // that lays the new size out: a panel still placed against the old, larger
  // screen is painted past the edge, and its rows wrap onto the next line.
  //
  // The placement is clamped into the new viewport, so it is already on screen
  // even though the anchor's box still describes the layout being replaced; the
  // next frame corrects it.
  //
  // Deferred because the first run would only place a panel the frame
  // handler has not placed yet.
  createEffect(
    on(
      () => [viewport().width, viewport().height] as const,
      () => applyPlacement(measurePlacement()),
      { defer: true },
    ),
  );

  // Close the panel on a left click; other buttons are left to the host.
  const handleClose = (event: MouseEvent): void => {
    if (event.button !== 0) {
      return;
    }
    event.stopPropagation();
    props.onClose?.();
  };

  // Swallow left clicks over the panel so they do not fall through to whatever
  // sits under it; other buttons are left to the host.
  const swallowClick = (event: MouseEvent): void => {
    if (event.button !== 0) {
      return;
    }
    event.stopPropagation();
  };

  // No placement means no anchor yet (nothing laid out), or an element the host
  // has destroyed; either way there is nothing to place the panel against.
  //
  // Keyed on the placement: the runtime applies a node's props
  // when it creates that node, so moving the panel through
  // `top`/`left` alone would leave it where it first landed.
  // A fresh panel per placement is what makes a move take effect, and the only
  // way its size follows the terminal, at the cost of rebuilding its content.
  return (
    <Show keyed when={placement()}>
      {(at) => (
        <box
          position="absolute"
          top={at.top}
          left={at.left}
          width={at.width}
          height={at.height}
          zIndex={6000}
          flexDirection="column"
          onMouseDown={swallowClick}
          onMouseUp={swallowClick}
        >
          <text
            fg={panelColor}
            selectable={false}
            wrapMode="none"
          >
            {TOP_CAP.repeat(at.width)}
          </text>
          <Show when={hasHeader()}>
            <box
              backgroundColor={panelColor}
              flexDirection="row"
              paddingX={BODY_PADDING_X}
              flexShrink={0}
            >
              {/* Balances the close glyph so the title still centres. */}
              <box width={1} flexShrink={0} />
              <box flexDirection="row" justifyContent="center" flexGrow={1}>
                <Show when={bodyView().title}>
                  {(title) => (
                    <text
                      fg={panelColor}
                      bg={context.theme.text.base}
                      selectable={false}
                      wrapMode="none"
                      truncate
                    >
                      {`${TITLE_PADDING}${title()}${TITLE_PADDING}`}
                    </text>
                  )}
                </Show>
              </box>
              <Show
                when={props.onClose !== undefined}
                fallback={<box width={1} flexShrink={0} />}
              >
                <text
                  fg={context.theme.text.muted}
                  selectable={false}
                  wrapMode="none"
                  onMouseUp={handleClose}
                >
                  {CLOSE_GLYPH}
                </text>
              </Show>
            </box>
          </Show>
          <box
            backgroundColor={panelColor}
            flexDirection="column"
            flexGrow={1}
          >
            <scrollbox
              height={layout().bodyRows}
              width="100%"
              scrollX={false}
              scrollY
              verticalScrollbarOptions={{ showArrows: false }}
            >
              <box flexDirection="column" paddingX={BODY_PADDING_X}>
                {body()}
              </box>
            </scrollbox>
          </box>
          <text
            fg={panelColor}
            selectable={false}
            wrapMode="none"
          >
            {BOTTOM_CAP.repeat(at.width)}
          </text>
        </box>
      )}
    </Show>
  );
}

// The body drawn when the caller has nothing to show: a centred note between
// blank rows, so the panel still has a size of its own.
function placeholderBody(contentWidth: number): TooltipBody {
  return {
    width: placeholderWidth(contentWidth),
    bodyRows: PLACEHOLDER_ROWS.length,
    content: <TooltipPlaceholder />,
  };
}

// The placeholder rows, centred on the panel background.
function TooltipPlaceholder() {
  return (
    <box flexDirection="column" width="100%" alignItems="center">
      <For each={PLACEHOLDER_ROWS}>
        {(row) => <text selectable={false}>{row}</text>}
      </For>
    </box>
  );
}
