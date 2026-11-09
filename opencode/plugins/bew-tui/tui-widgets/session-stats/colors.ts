// Colour helpers for the session stats line.

// Matches the `#rrggbb` colours the theme resolves to.
const HEX_COLOR_PATTERN = /^#[0-9a-f]{6}$/i;

// Brighten a colour by moving each channel toward white, keeping its hue.
//
// `amount` runs from 0 (unchanged) to 1 (white) and is clamped to that range.
// A colour in any other format (ANSI name, `rgb(...)`) is returned unchanged,
// since its channels cannot be read without parsing that format.
export function brightenColor(color: string, amount: number): string {
  if (!HEX_COLOR_PATTERN.test(color)) {
    return color;
  }
  const clamped = Math.min(1, Math.max(0, amount));
  const channels = [1, 3, 5].map((offset) =>
    brightenChannel(Number.parseInt(color.slice(offset, offset + 2), 16), clamped),
  );
  return `#${channels.join("")}`;
}

// Brighten one 0-255 channel and return it as two hex digits.
function brightenChannel(value: number, amount: number): string {
  const brightened = Math.round(value + (255 - value) * amount);
  return brightened.toString(16).padStart(2, "0");
}

// Default share by which a dimmed colour moves toward black.
const DEFAULT_DIM_AMOUNT = 0.45;

// Dim a colour by moving each channel toward black, keeping its hue.
//
// `amount` runs from 0 (unchanged) to 1 (black) and is clamped to that range.
// A colour in any other format is returned unchanged, as in `brightenColor`.
export function dimColor(
  color: string,
  amount: number = DEFAULT_DIM_AMOUNT,
): string {
  if (!HEX_COLOR_PATTERN.test(color)) {
    return color;
  }
  const clamped = Math.min(1, Math.max(0, amount));
  const channels = [1, 3, 5].map((offset) =>
    dimChannel(Number.parseInt(color.slice(offset, offset + 2), 16), clamped),
  );
  return `#${channels.join("")}`;
}

// Dim one 0-255 channel and return it as two hex digits.
function dimChannel(value: number, amount: number): string {
  const dimmed = Math.round(value * (1 - amount));
  return dimmed.toString(16).padStart(2, "0");
}
