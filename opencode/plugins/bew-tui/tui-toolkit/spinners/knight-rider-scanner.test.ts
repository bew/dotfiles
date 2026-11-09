// Tests for the ported knight-rider scanner primitive.

import { describe, expect, test } from "bun:test";
import { RGBA } from "@opentui/core";
import { createColorGenerator, createFrames } from "./knight-rider-scanner";
import type { ScannerOptions } from "./knight-rider-scanner";

// White keeps the channel math out of the assertions.
const WHITE = RGBA.fromValues(1, 1, 1, 1);

// The host footer's own scanner settings.
const FOOTER_OPTIONS: ScannerOptions = {
  color: WHITE,
  style: "blocks",
  width: 8,
  inactiveFactor: 0.6,
  minAlpha: 0.3,
};

// The four channels of a color, for comparison.
function channels(color: RGBA): number[] {
  return [color.r, color.g, color.b, color.a];
}

describe("createFrames", () => {
  test("covers a full bidirectional sweep", () => {
    // Forward (width) + hold end + backward (width - 1) + hold start.
    expect(createFrames(FOOTER_OPTIONS)).toHaveLength(8 + 9 + 7 + 30);
  });

  test("draws one cell per column", () => {
    for (const frame of createFrames(FOOTER_OPTIONS)) {
      expect(frame).toHaveLength(8);
    }
  });

  test("lights the trail behind the lead as the sweep advances", () => {
    const frames = createFrames(FOOTER_OPTIONS);
    // The lead starts alone, then drags a trail of the cells it passed.
    expect(frames[0]).toBe("■⬝⬝⬝⬝⬝⬝⬝");
    expect(frames[4]).toBe("■■■■■⬝⬝⬝");
    // The trail is capped at the ramp length, so the head cell dims first.
    expect(frames[6]).toBe("⬝■■■■■■⬝");
  });

  test("uses diamond glyphs when asked", () => {
    const frames = createFrames({ ...FOOTER_OPTIONS, style: "diamonds" });
    expect(frames[0]).toBe("⬥·······");
  });
});

describe("createColorGenerator", () => {
  const generate = createColorGenerator(FOOTER_OPTIONS);

  test("paints the lead cell at full strength", () => {
    expect(channels(generate(0, 0, 54, 8))).toEqual([1, 1, 1, 1]);
    expect(channels(generate(4, 4, 54, 8))).toEqual([1, 1, 1, 1]);
  });

  test("dims inactive cells by the fade and inactive factor", () => {
    // No movement yet, so the fade sits at its floor: 0.6 * 0.3.
    expect(generate(0, 1, 54, 8).a).toBeCloseTo(0.18);
  });

  test("leaves cells behind the hold trailing the lead", () => {
    // First hold frame: the lead is the last cell, the trail extends left.
    expect(channels(generate(8, 7, 54, 8))).toEqual([1, 1, 1, 1]);
    expect(generate(8, 1, 54, 8).a).toBeCloseTo(0.6);
  });
});
