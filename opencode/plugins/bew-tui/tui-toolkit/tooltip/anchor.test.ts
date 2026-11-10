// Tests for the tooltip anchor geometry.

import { describe, expect, test } from "bun:test";
import { rectOf } from "./anchor";

// A box that reports the fields an anchor reads.
function makeBox(screenX: number, screenY: number, width: number, height: number) {
  return { screenX, screenY, width, height };
}

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
