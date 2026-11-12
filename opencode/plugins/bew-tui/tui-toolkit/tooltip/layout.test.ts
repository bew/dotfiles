// Tests for the tooltip placement math.

import { describe, expect, test } from "bun:test";
import {
  TOOLTIP_LEFT_MARGIN,
  TOOLTIP_RIGHT_MARGIN,
  availableRows,
  defaultSide,
  resolveTooltipPosition,
} from "./layout";
import type {
  ContainerExtent,
  Rect,
  Size,
  TooltipPosition,
  TooltipSide,
} from "./layout";

// Tooltip size used by most cases.
const SIZE: Size = { width: 20, height: 4 };

// The area a panel is placed in: the whole terminal for most cases.
const AREA: ContainerExtent = { top: 0, height: 40 };

// Terminal width the horizontal margins are kept inside.
const VIEWPORT_WIDTH = 100;

// An anchor sitting in the middle of the area, on a row with room above.
function makeAnchor(overrides: Partial<Rect> = {}): Rect {
  return { x: 50, y: 20, width: 10, height: 1, ...overrides };
}

// Places SIZE against `anchor` on `side`, unless a case says otherwise.
function place(
  anchor: Rect,
  side: TooltipSide,
  size: Size = SIZE,
  area: ContainerExtent = AREA,
): TooltipPosition {
  return resolveTooltipPosition({
    anchor,
    side,
    size,
    area,
    viewportWidth: VIEWPORT_WIDTH,
  });
}

describe("defaultSide", () => {
  test("draws above an anchor in the lower half of the area", () => {
    expect(defaultSide(makeAnchor({ y: 25 }), AREA)).toBe("onTop");
  });

  test("draws below an anchor in the upper half of the area", () => {
    expect(defaultSide(makeAnchor({ y: 5 }), AREA)).toBe("onBottom");
  });

  test("draws above an anchor straddling the middle", () => {
    // Rows 19 and 20, whose middle row is the area's own middle row.
    expect(defaultSide(makeAnchor({ y: 19, height: 2 }), AREA)).toBe("onTop");
  });

  test("counts the middle from the area's own top", () => {
    const area: ContainerExtent = { top: 10, height: 20 };

    expect(defaultSide(makeAnchor({ y: 25 }), area)).toBe("onTop");
    expect(defaultSide(makeAnchor({ y: 15 }), area)).toBe("onBottom");
  });
});

describe("availableRows", () => {
  test("leaves the rows above the anchor", () => {
    expect(availableRows(makeAnchor({ y: 20 }), "onTop", AREA)).toBe(20);
  });

  test("leaves the rows below the anchor", () => {
    expect(availableRows(makeAnchor({ y: 20 }), "onBottom", AREA)).toBe(19);
  });

  test("leaves nothing at either edge of the area", () => {
    expect(availableRows(makeAnchor({ y: 0 }), "onTop", AREA)).toBe(0);
    expect(availableRows(makeAnchor({ y: 39 }), "onBottom", AREA)).toBe(0);
  });

  test("counts from the area's own edges", () => {
    const area: ContainerExtent = { top: 5, height: 30 };
    const anchor = makeAnchor({ y: 20 });

    expect(availableRows(anchor, "onTop", area)).toBe(15);
    expect(availableRows(anchor, "onBottom", area)).toBe(14);
  });
});

describe("resolveTooltipPosition", () => {
  test("sits above the anchor when that side is asked for", () => {
    expect(place(makeAnchor(), "onTop").top).toBe(16);
  });

  test("sits below the anchor when that side is asked for", () => {
    expect(place(makeAnchor(), "onBottom").top).toBe(21);
  });

  test("stays on its side when the room there is too small", () => {
    const anchor = makeAnchor({ y: 2 });

    // Four rows do not fit above a row-two anchor, and the panel does not move
    // below it either: it is placed at the area's top edge instead.
    expect(place(anchor, "onTop").top).toBe(0);
    expect(place(anchor, "onBottom").top).toBe(3);
  });

  test("lifts a panel that would run past the area's bottom edge", () => {
    const area: ContainerExtent = { top: 0, height: 10 };
    const anchor = makeAnchor({ y: 8 });

    // The rows below the anchor cannot hold the panel, so it is pulled up to
    // sit inside the area, over its anchor.
    expect(place(anchor, "onBottom", SIZE, area).top).toBe(6);
  });

  test("measures the panel from the area's top edge", () => {
    const area: ContainerExtent = { top: 5, height: 30 };

    expect(place(makeAnchor({ y: 20 }), "onTop", SIZE, area).top).toBe(11);
  });

  test("centres on an anchor narrower than the tooltip", () => {
    const anchor = makeAnchor({ x: 50, width: 4 });

    expect(place(anchor, "onTop").left).toBe(42);
  });

  test("centres on an anchor wider than the tooltip", () => {
    const anchor = makeAnchor({ x: 30, width: 60 });

    expect(place(anchor, "onTop").left).toBe(50);
  });

  test("keeps the margin at the right edge", () => {
    const anchor = makeAnchor({ x: 95, width: 5 });

    expect(place(anchor, "onTop").left).toBe(
      VIEWPORT_WIDTH - TOOLTIP_RIGHT_MARGIN - SIZE.width,
    );
  });

  test("keeps the margin at the left edge", () => {
    const anchor = makeAnchor({ x: 0, width: 2 });

    expect(place(anchor, "onTop").left).toBe(TOOLTIP_LEFT_MARGIN);
  });

  test("never returns a negative coordinate on a tiny terminal", () => {
    const area: ContainerExtent = { top: 0, height: 6 };
    const anchor = makeAnchor({ x: 0, y: 1, width: 2 });

    // Narrower than the right margin plus the panel, so the panel is left at
    // the left margin and that margin is itself cut off.
    const position = resolveTooltipPosition({
      anchor,
      side: "onTop",
      size: SIZE,
      area,
      viewportWidth: 10,
    });

    expect(position.left).toBe(0);
    expect(position.top).toBeGreaterThanOrEqual(0);
  });
});
