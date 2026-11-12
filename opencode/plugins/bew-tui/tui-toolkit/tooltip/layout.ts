// Placement math for the tooltip overlay.
//
// Kept free of renderer imports so the decision can be tested on its own.

// Gap kept between the tooltip's left edge and the terminal border, in cells.
export const TOOLTIP_LEFT_MARGIN = 2;

// Gap kept between the tooltip's right edge and the terminal border, in cells.
// Wider than the left gap, matching the spacing the composer's right edge uses.
export const TOOLTIP_RIGHT_MARGIN = 4;

// A box in terminal cells, in absolute screen coordinates.
export type Rect = {
  readonly x: number;
  readonly y: number;
  readonly width: number;
  readonly height: number;
};

// Width and height in terminal cells.
export type Size = {
  readonly width: number;
  readonly height: number;
};

// The area an overlay may occupy: the host's main area, which stops above the
// host's own bottom bars.
export type ContainerExtent = {
  // Row the area starts at, in terminal cells.
  readonly top: number;
  // Rows the area spans.
  readonly height: number;
};

// The side of its anchor a tooltip is drawn on: `onTop` draws it above the
// anchor, `onBottom` below it.
// The names state the edge of the anchor the panel is placed at, so a panel can
// later be placed at its left or right edge without renaming these.
export type TooltipSide = "onTop" | "onBottom";

// Where the tooltip lands, in cells from the area's top-left corner.
export type TooltipPosition = {
  readonly top: number;
  readonly left: number;
};

// Everything the placement decision reads.
export type TooltipGeometry = {
  // The box the tooltip points at, in terminal cells.
  readonly anchor: Rect;
  // The side drawn on; the panel stays there even when that side leaves it less
  // room than its content needs.
  readonly side: TooltipSide;
  // The panel's own size, already cut to the rows `side` leaves it.
  readonly size: Size;
  // The area the panel may occupy.
  readonly area: ContainerExtent;
  // Terminal width, in cells, that the horizontal margins are kept inside.
  readonly viewportWidth: number;
};

// The side to draw on when the caller states no preference.
//
// Draws `onTop` when the anchor's middle row sits in the area's lower half,
// `onBottom` otherwise: an anchor near the bottom, such as the composer, gets a
// panel above it, and one near the top gets a panel below.
export function defaultSide(anchor: Rect, area: ContainerExtent): TooltipSide {
  const anchorMiddle = anchor.y + anchor.height / 2;
  const areaMiddle = area.top + area.height / 2;
  return anchorMiddle >= areaMiddle ? "onTop" : "onBottom";
}

// Rows the area leaves on `side` of the anchor, the panel's frame included.
//
// Counted from the anchor's facing edge to the area's own edge, so an anchor on
// or past that edge leaves nothing rather than a negative count.
// A caller cuts its panel to this, which is what makes a tooltip with more
// content than room scroll instead of moving.
export function availableRows(
  anchor: Rect,
  side: TooltipSide,
  area: ContainerExtent,
): number {
  if (side === "onTop") {
    return Math.max(0, anchor.y - area.top);
  }
  return Math.max(0, area.top + area.height - (anchor.y + anchor.height));
}

// Places a tooltip against its anchor, on the side it was given.
//
// The panel is drawn on that side whether or not the whole of it fits there: a
// tooltip taller than the room is cut to the room by its caller and scrolls,
// rather than moving to the other side of its anchor.
// Horizontally it is centred on the anchor, then nudged back inside the
// terminal so its left edge keeps `TOOLTIP_LEFT_MARGIN` and its right edge
// keeps `TOOLTIP_RIGHT_MARGIN`.
// A terminal narrower than the right margin plus the tooltip leaves the
// tooltip at the left margin.
//
// Both coordinates are relative to `area`'s top-left corner, which is where an
// overlay inside the host's positioned box is drawn from.
export function resolveTooltipPosition(
  geometry: TooltipGeometry,
): TooltipPosition {
  const { anchor, side, size, area, viewportWidth } = geometry;
  const anchorRow = anchor.y - area.top;
  const wanted =
    side === "onTop" ? anchorRow - size.height : anchorRow + anchor.height;
  // A panel the area cannot hold, which only happens when the room is smaller
  // than the panel's own frame, is pulled back to sit inside the area.
  const lowestTop = Math.max(0, area.height - size.height);
  const top = Math.min(Math.max(0, wanted), lowestTop);
  const centred = anchor.x + (anchor.width - size.width) / 2;
  const maxLeft = viewportWidth - TOOLTIP_RIGHT_MARGIN - size.width;
  const left = Math.min(Math.max(TOOLTIP_LEFT_MARGIN, centred), maxLeft);

  return {
    top,
    left: Math.max(0, left),
  };
}
