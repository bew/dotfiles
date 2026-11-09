// Derives the anchor rectangle for a tooltip from a mouse event.

import type { Rect } from "./layout";

// The box fields an anchor needs, matching a renderable's absolute position.
export type AnchorBox = {
  readonly screenX: number;
  readonly screenY: number;
  readonly width: number;
  readonly height: number;
};

// The subset of a mouse event an anchor needs.
//
// Structural rather than the renderer's own type, so the derivation stays
// testable without a terminal.
export type AnchorEvent = {
  readonly x: number;
  readonly y: number;
  readonly target: AnchorBox | null;
  readonly currentTarget: AnchorBox | null;
};

// The box a mouse event landed on: the element the handler is attached to, then
// the hit-test target, or nothing when neither reports a box.
export function anchorBoxFromEvent(event: AnchorEvent): AnchorBox | undefined {
  return event.currentTarget ?? event.target ?? undefined;
}

// Anchor rectangle for a box, in absolute screen cells.
export function rectOf(box: AnchorBox): Rect {
  return {
    x: box.screenX,
    y: box.screenY,
    width: box.width,
    height: box.height,
  };
}

// Rect for the element a mouse event landed on.
//
// Prefers the current target — the element the handler is attached to — then the
// hit-test target, and falls back to the pointer cell when neither reports a box,
// which happens for host renderables that carry no target.
export function anchorFromEvent(event: AnchorEvent): Rect {
  const box = anchorBoxFromEvent(event);
  if (box === undefined) {
    return { x: event.x, y: event.y, width: 0, height: 1 };
  }

  return rectOf(box);
}
