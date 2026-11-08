// Tests for the color primitives behind the running indicator.

import { describe, expect, test } from "bun:test";
import { RGBA } from "@opentui/core";
import {
  deriveInactiveColor,
  deriveTrailColors,
  fadeColor,
} from "./colors";

// Compare a color's channels, allowing for OpenTUI's byte-scale round-trip.
function expectChannels(color: RGBA, expected: readonly number[]): void {
  const actual = [color.r, color.g, color.b, color.a];
  expected.forEach((value, index) => {
    expect(actual[index]).toBeCloseTo(value);
  });
}

describe("deriveTrailColors", () => {
  test("derives six steps by default", () => {
    expect(deriveTrailColors("#ff0000")).toHaveLength(6);
  });

  test("starts at the bright color, at full strength", () => {
    expectChannels(deriveTrailColors("#ff0000", 3)[0], [1, 0, 0, 1]);
  });

  test("brightens the glare behind the lead", () => {
    const ramp = deriveTrailColors("#808080", 3);
    expect(ramp[1].r).toBeGreaterThan(ramp[0].r);
    expect(ramp[1].a).toBeCloseTo(0.9);
  });

  test("clamps the glare at full strength", () => {
    expect(deriveTrailColors("#ffffff", 3)[1].r).toBeCloseTo(1);
  });

  test("falls off exponentially after the glare", () => {
    const ramp = deriveTrailColors("#00ff00", 4);
    expectChannels(ramp[2], [0, 1, 0, 0.65]);
    expectChannels(ramp[3], [0, 1, 0, 0.4225]);
  });

  test("accepts an RGBA color as well as a string", () => {
    const ramp = deriveTrailColors(RGBA.fromValues(0.25, 0.5, 0.75, 1), 1);
    expectChannels(ramp[0], [0.25, 0.5, 0.75, 1]);
  });
});

describe("deriveInactiveColor", () => {
  test("keeps the channels and drops the alpha", () => {
    expectChannels(deriveInactiveColor("#00ff00"), [0, 1, 0, 0.2]);
  });

  test("honours an explicit factor", () => {
    expectChannels(deriveInactiveColor("#0000ff", 0.6), [0, 0, 1, 0.6]);
  });
});

describe("fadeColor", () => {
  test("scales the alpha and keeps the channels", () => {
    expectChannels(fadeColor(RGBA.fromValues(1, 0.5, 0, 0.6), 0.5), [
      1,
      0.5,
      0,
      0.3,
    ]);
  });

  test("leaves the input color untouched", () => {
    const base = RGBA.fromValues(1, 1, 1, 0.6);
    fadeColor(base, 0);
    expect(base.a).toBeCloseTo(0.6);
  });
});
