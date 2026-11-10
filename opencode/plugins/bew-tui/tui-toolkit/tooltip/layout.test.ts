// Tests for the tooltip placement math.

import { describe, expect, test } from "bun:test";
import {
  TOOLTIP_LEFT_MARGIN,
  TOOLTIP_RIGHT_MARGIN,
  resolveTooltipPosition,
} from "./layout";
import type { Rect, Size } from "./layout";

// Tooltip size used by most cases.
const SIZE: Size = { width: 20, height: 4 };

// A terminal wide enough for the margin on both sides.
const VIEWPORT: Size = { width: 100, height: 40 };

// An anchor sitting in the middle of the terminal, on a row with room above.
function makeAnchor(overrides: Partial<Rect> = {}): Rect {
  return { x: 50, y: 20, width: 10, height: 1, ...overrides };
}

describe("resolveTooltipPosition", () => {
  test("sits above the anchor when there is room", () => {
    const position = resolveTooltipPosition(makeAnchor(), SIZE, VIEWPORT);

    expect(position.top).toBe(16);
  });

  test("goes below the anchor when the top would be off screen", () => {
    const anchor = makeAnchor({ y: 2 });

    const position = resolveTooltipPosition(anchor, SIZE, VIEWPORT);

    expect(position.top).toBe(3);
  });

  test("centres on an anchor narrower than the tooltip", () => {
    const anchor = makeAnchor({ x: 50, width: 4 });

    const position = resolveTooltipPosition(anchor, SIZE, VIEWPORT);

    expect(position.left).toBe(42);
  });

  test("centres on an anchor wider than the tooltip", () => {
    const anchor = makeAnchor({ x: 30, width: 60 });

    const position = resolveTooltipPosition(anchor, SIZE, VIEWPORT);

    expect(position.left).toBe(50);
  });

  test("keeps the margin at the right edge", () => {
    const anchor = makeAnchor({ x: 95, width: 5 });

    const position = resolveTooltipPosition(anchor, SIZE, VIEWPORT);

    expect(position.left).toBe(
      VIEWPORT.width - TOOLTIP_RIGHT_MARGIN - SIZE.width,
    );
  });

  test("keeps the margin at the left edge", () => {
    const anchor = makeAnchor({ x: 0, width: 2 });

    const position = resolveTooltipPosition(anchor, SIZE, VIEWPORT);

    expect(position.left).toBe(TOOLTIP_LEFT_MARGIN);
  });

  test("lifts a panel that would run off the bottom edge", () => {
    const shortViewport: Size = { width: 100, height: 10 };
    const tallSize: Size = { width: 20, height: 8 };
    const anchor = makeAnchor({ y: 3 });

    const position = resolveTooltipPosition(anchor, tallSize, shortViewport);

    expect(position.top).toBe(shortViewport.height - tallSize.height);
  });

  test("keeps a panel as tall as the terminal at the top edge", () => {
    const shortViewport: Size = { width: 100, height: 4 };
    const anchor = makeAnchor({ y: 29 });

    const position = resolveTooltipPosition(anchor, SIZE, shortViewport);

    expect(position.top).toBe(0);
  });

  test("never returns a negative coordinate on a tiny terminal", () => {
    const tinyViewport: Size = { width: 10, height: 6 };
    const anchor = makeAnchor({ x: 0, y: 1, width: 2 });

    const position = resolveTooltipPosition(anchor, SIZE, tinyViewport);

    expect(position.left).toBe(0);
    expect(position.top).toBeGreaterThanOrEqual(0);
  });
});
