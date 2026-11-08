// Color primitives for trail ramps and dimming, shared across components.
//
// The trail ramp derived from a bright color, and the dimming applied to the
// cells outside that ramp.
// Values are OpenTUI colors, so they reach the renderer as its own type.

import { RGBA, parseColor } from "@opentui/core";
import type { ColorInput } from "@opentui/core";

// Trail steps derived from a bright color when the caller does not choose.
const DEFAULT_TRAIL_STEPS = 6;

// Alpha of a cell outside the trail before fading, when the caller does not
// choose a factor.
const DEFAULT_INACTIVE_FACTOR = 0.2;

// Derive the trail ramp from one bright color: the lead at full strength, a
// slightly brightened glare behind it, then an exponential alpha falloff.
export function deriveTrailColors(
  brightColor: ColorInput,
  steps: number = DEFAULT_TRAIL_STEPS,
): RGBA[] {
  const bright = parseColor(brightColor);

  return Array.from({ length: steps }, (_, index) => {
    if (index === 0) {
      return RGBA.fromValues(bright.r, bright.g, bright.b, 1);
    }
    if (index === 1) {
      return RGBA.fromValues(
        Math.min(1, bright.r * 1.15),
        Math.min(1, bright.g * 1.15),
        Math.min(1, bright.b * 1.15),
        0.9,
      );
    }
    return RGBA.fromValues(
      bright.r,
      bright.g,
      bright.b,
      Math.pow(0.65, index - 1),
    );
  });
}

// Derive the color of a cell outside the trail: the bright color's channels with
// the alpha dropped to `factor`.
export function deriveInactiveColor(
  brightColor: ColorInput,
  factor: number = DEFAULT_INACTIVE_FACTOR,
): RGBA {
  const bright = parseColor(brightColor);

  return RGBA.fromValues(bright.r, bright.g, bright.b, factor);
}

// Copy `color` with its alpha scaled by `fadeFactor` (0..1), the multiplier an
// inactive cell is dimmed by as the scanner moves.
export function fadeColor(color: RGBA, fadeFactor: number): RGBA {
  return RGBA.fromValues(color.r, color.g, color.b, color.a * fadeFactor);
}
