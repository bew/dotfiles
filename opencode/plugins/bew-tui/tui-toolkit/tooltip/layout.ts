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

// Where the tooltip lands, and which side of its anchor it ended up on.
export type TooltipPosition = {
  readonly top: number;
  readonly left: number;
  readonly placement: "above" | "below";
};

// Places a tooltip next to `anchor`.
//
// The tooltip goes above the anchor when it fits there, otherwise below it.
// Horizontally it is centred on the anchor, then nudged back inside the terminal
// so its left edge keeps `TOOLTIP_LEFT_MARGIN` and its right edge keeps
// `TOOLTIP_RIGHT_MARGIN`. A terminal narrower than the right margin plus the
// tooltip leaves the tooltip at the left margin.
//
// Vertically the panel is kept inside the terminal too: a spot that would push
// its last row past the bottom edge is lifted until it fits, and one that would
// start above the top edge is pushed down.
export function resolveTooltipPosition(
  anchor: Rect,
  size: Size,
  viewport: Size,
): TooltipPosition {
  const fitsAbove = anchor.y - size.height >= 0;
  const preferred = fitsAbove ? anchor.y - size.height : anchor.y + anchor.height;
  const maxTop = Math.max(0, viewport.height - size.height);
  const top = Math.min(Math.max(0, preferred), maxTop);
  const centred = anchor.x + (anchor.width - size.width) / 2;
  const maxLeft = viewport.width - TOOLTIP_RIGHT_MARGIN - size.width;
  const left = Math.min(Math.max(TOOLTIP_LEFT_MARGIN, centred), maxLeft);

  return {
    top,
    left: Math.max(0, left),
    placement: fitsAbove ? "above" : "below",
  };
}
