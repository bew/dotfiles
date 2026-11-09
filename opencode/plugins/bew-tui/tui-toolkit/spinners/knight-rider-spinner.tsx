/** @jsxImportSource @opentui/solid */
// Knight-rider spinner view for plugin-owned regions.
//
// Wraps OpenCode's globally registered `<spinner>` element with the ported
// knight-rider frames and colors, so a region the plugin replaces can show the
// same running indicator the host does.
// The frames and the per-cell color maths live in `knight-rider-scanner.ts`.

import type { ColorInput } from "@opentui/core";
import { createMemo } from "solid-js";
import { createColorGenerator, createFrames } from "./knight-rider-scanner";
import type { ScannerOptions, ScannerStyle } from "./knight-rider-scanner";

// Milliseconds between scanner steps; the host footer uses 40.
const SCANNER_INTERVAL_MS = 40;

// Scanner settings matching the host footer's running indicator.
const SCANNER_STYLE: ScannerStyle = "blocks";
const SCANNER_WIDTH = 8;
const SCANNER_INACTIVE_FACTOR = 0.6;
const SCANNER_MIN_ALPHA = 0.3;

// The knight-rider sweep: a scanner trail in the given color.
export function KnightRiderSpinner(props: {
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
