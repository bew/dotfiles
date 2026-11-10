// Width maths for the session-stats tooltip: how many cells its rows are packed
// for, and how many its values get back.
//
// Kept free of renderer and JSX imports so the packing stays testable.

import { measureInsightWidth } from "./insights";
import type { InsightLayout, InsightSection } from "./insights";

// Column width of a row's label, in cells, so values line up between rows.
export const LABEL_WIDTH = 9;

// Cells between a row's label column and its value.
export const LABEL_GAP = 1;

// Cells a detail row spends on its prefix, in place of the label column: the
// bar or corner alone, with the row's gap supplying the space after it.
export const DETAIL_INDENT = 1;

// Widest body the rows are packed for, in cells, however wide the content is.
export const TOOLTIP_MAX_WIDTH = 64;

// Narrowest body worth drawing, in cells, unless the terminal leaves less.
export const TOOLTIP_MIN_WIDTH = 30;

// Layout the insight rows are measured against.
const TOOLTIP_LAYOUT: InsightLayout = {
  labelWidth: LABEL_WIDTH,
  detailIndent: DETAIL_INDENT,
  labelGap: LABEL_GAP,
};

// Cells a row's value column offers inside a body of
// `contentWidth`, after its label column and the gap after it.
export function valueWidth(contentWidth: number): number {
  return Math.max(1, contentWidth - LABEL_WIDTH - LABEL_GAP);
}

// Cells the body needs for the sections, no wider than
// `widthLimit`: wide enough for the widest rendered line, and
// at least the preferred minimum while the limit allows it.
export function contentWidth(
  sections: readonly InsightSection[],
  widthLimit: number,
): number {
  const content = measureInsightWidth(sections, TOOLTIP_LAYOUT);
  const minimum = Math.min(TOOLTIP_MIN_WIDTH, widthLimit);
  return Math.min(widthLimit, Math.max(minimum, content));
}
