// Anchor geometry for the tooltip overlay: the box an anchored element
// occupies, and the ref the panel reads it from.

import type { Rect } from "./layout";

// The box fields an anchor needs, matching a renderable's absolute position.
export type AnchorBox = {
  readonly screenX: number;
  readonly screenY: number;
  readonly width: number;
  readonly height: number;
};

// Ref for the element a tooltip points at, read again after every presented
// frame and on a terminal resize, so the box follows that element as
// the layout moves it.
//
// Yields nothing while the element is not laid out yet, or once the host has
// destroyed it; the panel then draws nothing rather than placing itself
// beside stale geometry.
export type AnchorRef = () => AnchorBox | undefined;

// Anchor rectangle for a box, in absolute screen cells.
//
// Reads the box at call time, so a live element that moved
// reports its new position.
export function rectOf(box: AnchorBox): Rect {
  return {
    x: box.screenX,
    y: box.screenY,
    width: box.width,
    height: box.height,
  };
}
