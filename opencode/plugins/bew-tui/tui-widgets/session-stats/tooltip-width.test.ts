// Tests for the tooltip width maths.

import { describe, expect, test } from "bun:test";
import type { InsightSection } from "./insights";
import {
  LABEL_GAP,
  LABEL_WIDTH,
  TOOLTIP_MAX_WIDTH,
  TOOLTIP_MIN_WIDTH,
  contentWidth,
  valueWidth,
} from "./tooltip-width";

// A section with one row of `text` and no heading, so the measured width is the
// row's width alone.
function makeSection(text: string): InsightSection {
  return {
    heading: "",
    rows: [{ label: "turns", segments: [{ text }] }],
  };
}

// Cells a labelled row spends before its value: the label column and its gap.
const ROW_OVERHEAD = LABEL_WIDTH + LABEL_GAP;

describe("valueWidth", () => {
  test("offers the cells left after the row's label and gap", () => {
    expect(valueWidth(38)).toBe(38 - ROW_OVERHEAD);
  });

  test("never offers less than one cell, however narrow the body", () => {
    expect(valueWidth(ROW_OVERHEAD)).toBe(1);
    expect(valueWidth(1)).toBe(1);
  });
});

describe("contentWidth", () => {
  test("keeps the preferred minimum for a narrow readout", () => {
    expect(contentWidth([makeSection("short")], TOOLTIP_MAX_WIDTH)).toBe(
      TOOLTIP_MIN_WIDTH,
    );
  });

  test("hugs content wider than the minimum", () => {
    const text = "x".repeat(40);
    // The row is the label column, the gap, then the value.
    expect(contentWidth([makeSection(text)], TOOLTIP_MAX_WIDTH)).toBe(
      ROW_OVERHEAD + text.length,
    );
  });

  test("never exceeds the width limit", () => {
    const text = "x".repeat(200);
    expect(contentWidth([makeSection(text)], 40)).toBe(40);
  });

  test("shrinks the minimum to a limit narrower than it", () => {
    expect(contentWidth([makeSection("short")], 20)).toBe(20);
  });

  test("measures the widest of heading and rows", () => {
    const heading = "a".repeat(50);
    const sections: readonly InsightSection[] = [
      { heading, rows: [] },
      makeSection("short"),
    ];
    expect(contentWidth(sections, TOOLTIP_MAX_WIDTH)).toBe(heading.length);
  });
});
