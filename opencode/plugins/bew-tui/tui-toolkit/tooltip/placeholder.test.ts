// Tests for the tooltip placeholder body's width.

import { describe, expect, test } from "bun:test";
import { PLACEHOLDER_ROWS, placeholderWidth } from "./placeholder";

describe("placeholderWidth", () => {
  test("asks for no more than the note it draws", () => {
    expect(placeholderWidth(64)).toBeLessThanOrEqual(24);
  });

  test("shrinks to the cells the panel offers", () => {
    expect(placeholderWidth(10)).toBe(10);
  });

  test("never asks for less than one cell", () => {
    expect(placeholderWidth(0)).toBe(1);
    expect(placeholderWidth(-5)).toBe(1);
  });
});

describe("PLACEHOLDER_ROWS", () => {
  test("centres the note between blank rows", () => {
    expect(PLACEHOLDER_ROWS).toHaveLength(5);
    expect(PLACEHOLDER_ROWS[2]).toBe("no data");
    expect(PLACEHOLDER_ROWS.filter((row) => row === " ")).toHaveLength(4);
  });
});
