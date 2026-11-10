// The body a tooltip shows when its caller has nothing to draw.

// Rows the placeholder body shows: the label centred between blank
// rows above and below it.
export const PLACEHOLDER_ROWS = [" ", " ", "no data", " ", " "] as const;

// Widest the placeholder body gets, in cells: narrow enough to read as a note,
// and shrunk further when the panel offers less room.
const PLACEHOLDER_WIDTH = 24;

// Cells the placeholder body asks for, given the cells its panel offers.
//
// Never wider than the note it draws, so an empty tooltip does not stretch to
// the caller's preferred width.
export function placeholderWidth(contentWidth: number): number {
  return Math.min(Math.max(1, contentWidth), PLACEHOLDER_WIDTH);
}
