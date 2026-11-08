/** @jsxImportSource @opentui/solid */
// Running-spinner view for plugin-owned footer regions.
//
// Wraps OpenCode's globally registered `<spinner>` element with the ported
// knight-rider frames and colors, so a component that replaces a footer slot
// can show the same running indicator the host does.
// Also carries the compact braille loader a component shows while slow
// background work runs.

import { parseColor } from "@opentui/core";
import type { ColorInput } from "@opentui/core";
import { createMemo } from "solid-js";
import { createColorGenerator, createFrames } from "./knight-rider-scanner";
import type { ScannerOptions, ScannerStyle } from "./knight-rider-scanner";

// Milliseconds between scanner steps; the host footer uses 40.
const SCANNER_INTERVAL_MS = 40;

// Braille loader frames, each one cell wide.
const BRAILLE_FRAMES = [
  "\u{280b}",
  "\u{2819}",
  "\u{2839}",
  "\u{2838}",
  "\u{283c}",
  "\u{2834}",
  "\u{2826}",
  "\u{2827}",
  "\u{2807}",
  "\u{280f}",
];

// Milliseconds between braille frames.
const BRAILLE_INTERVAL_MS = 80;

// Scanner settings matching the host footer's running indicator.
const SCANNER_STYLE: ScannerStyle = "blocks";
const SCANNER_WIDTH = 8;
const SCANNER_INACTIVE_FACTOR = 0.6;
const SCANNER_MIN_ALPHA = 0.3;

// The running indicator: a knight-rider sweep in the given color.
export function RunningSpinner(props: {
  // Bright color the trail is derived from, as a theme color or an RGBA value.
  readonly color: ColorInput;
  // Trail shape. Defaults to the host footer's blocks.
  readonly style?: ScannerStyle;
  // Milliseconds between steps. Defaults to the host footer's 40.
  readonly interval?: number;
}) {
  // Rebuild frames and colors only when the color or style changes.
  const scanner = createMemo(() => {
    const options: ScannerOptions = {
      color: props.color,
      style: props.style ?? SCANNER_STYLE,
      width: SCANNER_WIDTH,
      inactiveFactor: SCANNER_INACTIVE_FACTOR,
      minAlpha: SCANNER_MIN_ALPHA,
    };
    return {
      frames: createFrames(options),
      color: createColorGenerator(options),
    };
  });

  return (
    <spinner
      frames={scanner().frames}
      color={scanner().color}
      interval={props.interval ?? SCANNER_INTERVAL_MS}
    />
  );
}

// A one-cell braille loader in a fixed color, for slow background work a footer
// component runs.
export function BrailleSpinner(props: { readonly color: ColorInput }) {
  const color = createMemo(() => parseColor(props.color));
  return (
    <spinner
      frames={BRAILLE_FRAMES}
      color={() => color()}
      interval={BRAILLE_INTERVAL_MS}
    />
  );
}
