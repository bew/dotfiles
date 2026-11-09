/** @jsxImportSource @opentui/solid */
// Tooltip overlay: a small panel placed next to a hovered element.
//
// The caller owns the hover state and renders this in a slot that allows
// absolute positioning (the `app` slot works, since its box is the main area).

import { usePlugin } from "@opencode/plugin/tui";
import { useTerminalDimensions } from "@opentui/solid";
import type { MouseEvent } from "@opentui/core";
import { createMemo, Show } from "solid-js";
import type { JSX } from "solid-js";
import { resolveTooltipPosition } from "./layout";
import type { Rect } from "./layout";
import { rectOf } from "./anchor";
import type { AnchorBox } from "./anchor";

// Default tooltip width in terminal cells.
const DEFAULT_WIDTH = 38;

// Cells the body pads each side by, before its rows start.
export const BODY_PADDING_X = 1;

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

// Everything the tooltip needs to render.
export type TooltipProps = {
  // Element the tooltip points at, in absolute screen cells.
  readonly anchor: Rect;
  // Live box of the anchored element. When given, the anchor is re-read on each
  // layout pass instead of using `anchor`, so the panel follows a terminal resize
  // that moves the element.
  readonly anchorSource?: AnchorBox;
  // Tooltip width in cells, padding included.
  readonly width?: number;
  // Rows the children occupy, so the panel can size itself; the cap rows and
  // the title band are added on top of this count.
  readonly bodyRows: number;
  // Optional heading, rendered centred above the children in an inverted band
  // (panel colour on the text colour) with padding on both sides.
  readonly title?: string;
  // Body content, rendered on the panel background.
  readonly children?: JSX.Element;
  // Called when the close glyph is clicked. A tooltip without it cannot be
  // dismissed from the panel itself and shows no close control.
  readonly onClose?: () => void;
};

// The tooltip panel: half-block caps around a filled body, placed near `anchor`.
//
// The panel goes above the anchor when it fits, below it otherwise, and is
// centred on the anchor while staying inside the terminal margins.
//
// The panel sizes itself: the caller supplies the body-row count and the frame
// adds its own cap and title rows.
//
// A panel taller than the terminal is cut to the terminal height, and its body
// scrolls.
export function Tooltip(props: TooltipProps) {
  const context = usePlugin();
  const viewport = useTerminalDimensions();

  const width = props.width ?? DEFAULT_WIDTH;
  const hasHeader = () =>
    props.title !== undefined || props.onClose !== undefined;

  // The panel's own size, recomputed when its body or the terminal changes, so a
  // tooltip that replaces another does not keep the earlier height.
  //
  // A panel taller than the terminal is cut to the terminal height, and its body
  // scrolls, so its rows never run off the screen.
  const layout = createMemo(() => {
    const frameRows = CAP_ROWS + (hasHeader() ? HEADER_ROWS : 0);
    const maxRows = Math.max(frameRows + 2, viewport().height);
    const fullHeight = frameRows + props.bodyRows;
    const height = Math.min(fullHeight, maxRows);
    // Rows the body shows at once; the rest stay reachable by scrolling.
    return { height, bodyRows: height - frameRows };
  });

  // Fill colour of the tooltip body.
  const panelColor = context.theme.hue.gray[600];

  // The caps carry no background: the half-block glyph is drawn in the panel
  // colour and the half it leaves free shows the terminal background.

  const position = () =>
    resolveTooltipPosition(
      props.anchorSource === undefined ? props.anchor : rectOf(props.anchorSource),
      { width, height: layout().height },
      viewport(),
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

  return (
    <box
      position="absolute"
      top={position().top}
      left={position().left}
      width={width}
      height={layout().height}
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
        {TOP_CAP.repeat(width)}
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
            <Show when={props.title}>
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
            {props.children}
          </box>
        </scrollbox>
      </box>
      <text
        fg={panelColor}
        selectable={false}
        wrapMode="none"
      >
        {BOTTOM_CAP.repeat(width)}
      </text>
    </box>
  );
}
