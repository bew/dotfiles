// Knight-rider scanner animation for the running indicator.
//
// Ported from OpenCode's own footer spinner, so the running look matches the
// host's.
// Emits one glyph frame per sweep step, plus the per-cell color function the
// spinner draws those frames with.

import type { ColorInput, RGBA } from "@opentui/core";
import {
  deriveInactiveColor,
  deriveTrailColors,
  fadeColor,
} from "../../lib/colors";

// Trail shape: solid blocks, or a ladder of diamonds and arrows.
export type ScannerStyle = "blocks" | "diamonds";

// Shape and color settings for the scanner.
export type ScannerOptions = {
  // Bright color the trail ramp is derived from.
  readonly color: ColorInput;
  // Trail shape. Default "diamonds".
  readonly style?: ScannerStyle;
  // Cells per frame. Default 8.
  readonly width?: number;
  // Frames held at the sweep's start. Default 30.
  readonly holdStart?: number;
  // Frames held at the sweep's end. Default 9.
  readonly holdEnd?: number;
  // Trail steps derived from `color`. Default 6.
  readonly trailSteps?: number;
  // Alpha of inactive cells before fading. Default 0.2.
  readonly inactiveFactor?: number;
  // Fade inactive cells during hold and movement. Default true.
  readonly enableFading?: boolean;
  // Floor for the fading alpha, in 0..1. Default 0.
  readonly minAlpha?: number;
};

// Per-cell color function, in the argument order the host's spinner calls it.
export type CellColorGenerator = (
  frameIndex: number,
  charIndex: number,
  totalFrames: number,
  totalChars: number,
) => RGBA;

// Default trail metrics, matching OpenCode's footer spinner.
const DEFAULT_WIDTH = 8;
const DEFAULT_HOLD_START = 30;
const DEFAULT_HOLD_END = 9;

// Block-trail glyphs: one for the lit cells, one for the dark cells.
const BLOCK_TRAIL_ACTIVE = "■";
const BLOCK_TRAIL_INACTIVE = "⬝";
// Diamond-trail glyphs, brightest first; dark cells use the diamond-inactive one.
const DIAMOND_TRAIL_GLYPHS = ["⬥", "◆", "⬩", "⬪"] as const;
const DIAMOND_TRAIL_INACTIVE = "·";

// Scanner values precomputed from the public options.
type ScannerShape = {
  readonly style: ScannerStyle;
  readonly width: number;
  readonly holdStart: number;
  readonly holdEnd: number;
  readonly colors: readonly RGBA[];
  readonly inactiveColor: RGBA;
  readonly enableFading: boolean;
  readonly minAlpha: number;
};

// The moving scanner at one frame: where the lead is, and how far into a hold
// or a movement the frame is.
type ScannerState = {
  readonly activePosition: number;
  readonly isHolding: boolean;
  readonly holdProgress: number;
  readonly holdTotal: number;
  readonly movementProgress: number;
  readonly movementTotal: number;
  readonly isMovingForward: boolean;
};

// Build one frame per step of the bidirectional sweep, each a string of glyphs.
export function createFrames(options: ScannerOptions): string[] {
  const shape = resolveShape(options);
  const totalFrames =
    shape.width + shape.holdEnd + (shape.width - 1) + shape.holdStart;

  return Array.from({ length: totalFrames }, (_, frameIndex) => {
    const state = getScannerState(
      frameIndex,
      shape.width,
      shape.holdStart,
      shape.holdEnd,
    );
    return Array.from({ length: shape.width }, (_, charIndex) =>
      cellGlyph(
        shape.style,
        trailIndex(charIndex, shape.colors.length, state),
        shape.colors.length,
      ),
    ).join("");
  });
}

// Build the per-cell color function the spinner calls for every drawn cell.
// Cells outside the trail ramp are inactive, dimmed by the current fade.
export function createColorGenerator(
  options: ScannerOptions,
): CellColorGenerator {
  const shape = resolveShape(options);

  return (frameIndex, charIndex, _totalFrames, totalChars) => {
    const state = getScannerState(
      frameIndex,
      totalChars,
      shape.holdStart,
      shape.holdEnd,
    );
    const index = trailIndex(charIndex, shape.colors.length, state);
    const isActive = index >= 0 && index < shape.colors.length;

    if (isActive) {
      return shape.colors[index];
    }
    return fadeColor(shape.inactiveColor, computeFadeFactor(state, shape));
  };
}

// Expand the public options into the values the scanner math needs.
function resolveShape(options: ScannerOptions): ScannerShape {
  return {
    style: options.style ?? "diamonds",
    width: options.width ?? DEFAULT_WIDTH,
    holdStart: options.holdStart ?? DEFAULT_HOLD_START,
    holdEnd: options.holdEnd ?? DEFAULT_HOLD_END,
    colors: deriveTrailColors(options.color, options.trailSteps),
    inactiveColor: deriveInactiveColor(options.color, options.inactiveFactor),
    enableFading: options.enableFading ?? true,
    minAlpha: options.minAlpha ?? 0,
  };
}

// Resolve the moving scanner at one frame of the bidirectional sweep: forward
// across the cells, hold at the end, backward, then hold at the start.
function getScannerState(
  frameIndex: number,
  totalChars: number,
  holdStart: number,
  holdEnd: number,
): ScannerState {
  const forwardFrames = totalChars;
  if (frameIndex < forwardFrames) {
    return {
      activePosition: frameIndex,
      isHolding: false,
      holdProgress: 0,
      holdTotal: 0,
      movementProgress: frameIndex,
      movementTotal: forwardFrames,
      isMovingForward: true,
    };
  }

  const backwardStart = forwardFrames + holdEnd;
  const backwardFrames = totalChars - 1;

  if (frameIndex < backwardStart) {
    return {
      activePosition: totalChars - 1,
      isHolding: true,
      holdProgress: frameIndex - forwardFrames,
      holdTotal: holdEnd,
      movementProgress: 0,
      movementTotal: 0,
      isMovingForward: true,
    };
  }

  if (frameIndex < backwardStart + backwardFrames) {
    const backwardIndex = frameIndex - backwardStart;
    return {
      activePosition: totalChars - 2 - backwardIndex,
      isHolding: false,
      holdProgress: 0,
      holdTotal: 0,
      movementProgress: backwardIndex,
      movementTotal: backwardFrames,
      isMovingForward: false,
    };
  }

  return {
    activePosition: 0,
    isHolding: true,
    holdProgress: frameIndex - backwardStart - backwardFrames,
    holdTotal: holdStart,
    movementProgress: 0,
    movementTotal: 0,
    isMovingForward: false,
  };
}

// Index into the trail ramp for one cell, or a value outside the ramp when the
// cell is inactive. A holding scanner extends the trail with how long it held.
function trailIndex(
  charIndex: number,
  trailLength: number,
  state: ScannerState,
): number {
  const directionalDistance = state.isMovingForward
    ? state.activePosition - charIndex
    : charIndex - state.activePosition;

  if (state.isHolding) {
    return directionalDistance + state.holdProgress;
  }

  if (directionalDistance > 0 && directionalDistance < trailLength) {
    return directionalDistance;
  }

  if (directionalDistance === 0) {
    return 0;
  }

  return -1;
}

// Alpha multiplier for the inactive cells at one scanner state, so the dark
// cells fade in as the lead moves and fade out as it holds.
function computeFadeFactor(state: ScannerState, shape: ScannerShape): number {
  if (!shape.enableFading) {
    return 1;
  }

  if (state.isHolding && state.holdTotal > 0) {
    const progress = Math.min(state.holdProgress / state.holdTotal, 1);
    return Math.max(shape.minAlpha, 1 - progress * (1 - shape.minAlpha));
  }

  if (!state.isHolding && state.movementTotal > 0) {
    const progress = Math.min(
      state.movementProgress / Math.max(1, state.movementTotal - 1),
      1,
    );
    return shape.minAlpha + progress * (1 - shape.minAlpha);
  }

  return 1;
}

// Glyph for one cell, chosen by trail style and whether the cell is lit.
function cellGlyph(
  style: ScannerStyle,
  index: number,
  trailLength: number,
): string {
  const isActive = index >= 0 && index < trailLength;

  if (style === "diamonds") {
    if (!isActive) {
      return DIAMOND_TRAIL_INACTIVE;
    }
    return DIAMOND_TRAIL_GLYPHS[
      Math.min(index, DIAMOND_TRAIL_GLYPHS.length - 1)
    ];
  }

  return isActive ? BLOCK_TRAIL_ACTIVE : BLOCK_TRAIL_INACTIVE;
}
