/** @jsxImportSource @opentui/solid */
// Braille spinner view for plugin-owned regions.
//
// A one-cell loader for slow background work a widget runs, such as a `git
// status` call that has not answered yet.

import { parseColor } from "@opentui/core";
import type { ColorInput } from "@opentui/core";
import { createMemo } from "solid-js";

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

// A one-cell braille loader in a fixed color.
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
