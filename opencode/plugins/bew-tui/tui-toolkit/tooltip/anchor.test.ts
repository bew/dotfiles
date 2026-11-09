// Tests for deriving a tooltip anchor from a mouse event.

import { describe, expect, test } from "bun:test";
import { anchorBoxFromEvent, anchorFromEvent, rectOf } from "./anchor";
import type { AnchorEvent } from "./anchor";

// A box that reports the fields an anchor reads.
function makeBox(screenX: number, screenY: number, width: number, height: number) {
  return { screenX, screenY, width, height };
}

// Event shape with everything absent unless overridden.
function makeEvent(overrides: Partial<AnchorEvent> = {}): AnchorEvent {
  return { x: 7, y: 9, target: null, currentTarget: null, ...overrides };
}

describe("anchorFromEvent", () => {
  test("uses the current target's absolute box", () => {
    const anchor = anchorFromEvent(
      makeEvent({ currentTarget: makeBox(12, 20, 30, 1) }),
    );

    expect(anchor).toEqual({ x: 12, y: 20, width: 30, height: 1 });
  });

  test("falls back to the hit-test target", () => {
    const anchor = anchorFromEvent(makeEvent({ target: makeBox(4, 5, 6, 1) }));

    expect(anchor).toEqual({ x: 4, y: 5, width: 6, height: 1 });
  });

  test("prefers the current target over the hit-test target", () => {
    const anchor = anchorFromEvent(
      makeEvent({
        currentTarget: makeBox(12, 20, 30, 1),
        target: makeBox(4, 5, 6, 1),
      }),
    );

    expect(anchor.x).toBe(12);
  });

  test("falls back to the pointer cell when no box is reported", () => {
    const anchor = anchorFromEvent(makeEvent());

    expect(anchor).toEqual({ x: 7, y: 9, width: 0, height: 1 });
  });
});

describe("anchorBoxFromEvent", () => {
  test("returns the current target's box", () => {
    const box = makeBox(12, 20, 30, 1);

    expect(anchorBoxFromEvent(makeEvent({ currentTarget: box }))).toBe(box);
  });

  test("returns nothing when no box is reported", () => {
    expect(anchorBoxFromEvent(makeEvent())).toBeUndefined();
  });
});

describe("rectOf", () => {
  test("maps the box onto the anchor rectangle", () => {
    expect(rectOf(makeBox(3, 4, 5, 1))).toEqual({
      x: 3,
      y: 4,
      width: 5,
      height: 1,
    });
  });

  test("reads the box again, so a moved element gives a new rectangle", () => {
    const box = { screenX: 3, screenY: 4, width: 5, height: 1 };
    const rect = rectOf(box);

    box.screenY = 12;

    expect(rect.y).toBe(4);
    expect(rectOf(box).y).toBe(12);
  });
});
