// Tests for the colour helpers.

import { describe, expect, test } from "bun:test";
import { brightenColor, dimColor } from "./colors";

describe("brightenColor", () => {
  test("moves every channel toward white", () => {
    expect(brightenColor("#000000", 0.35)).toBe("#595959");
    expect(brightenColor("#ff0000", 0.5)).toBe("#ff8080");
  });

  test("leaves the colour unchanged at amount 0", () => {
    expect(brightenColor("#123456", 0)).toBe("#123456");
  });

  test("reaches white at amount 1", () => {
    expect(brightenColor("#123456", 1)).toBe("#ffffff");
  });

  test("clamps an out-of-range amount", () => {
    expect(brightenColor("#000000", 2)).toBe("#ffffff");
    expect(brightenColor("#123456", -1)).toBe("#123456");
  });

  test("accepts uppercase hex", () => {
    expect(brightenColor("#FF0000", 0.5)).toBe("#ff8080");
  });

  test("returns non-hex colours unchanged", () => {
    expect(brightenColor("red", 0.5)).toBe("red");
    expect(brightenColor("#fff", 0.5)).toBe("#fff");
    expect(brightenColor("rgb(1, 2, 3)", 0.5)).toBe("rgb(1, 2, 3)");
  });
});

describe("dimColor", () => {
  test("moves every channel toward black", () => {
    expect(dimColor("#ffffff", 0.5)).toBe("#808080");
    expect(dimColor("#ff0000", 0.5)).toBe("#800000");
  });

  test("leaves the colour unchanged at amount 0", () => {
    expect(dimColor("#123456", 0)).toBe("#123456");
  });

  test("reaches black at amount 1", () => {
    expect(dimColor("#123456", 1)).toBe("#000000");
  });

  test("clamps an out-of-range amount", () => {
    expect(dimColor("#123456", 2)).toBe("#000000");
    expect(dimColor("#123456", -1)).toBe("#123456");
  });

  test("defaults to a partial dim", () => {
    expect(dimColor("#ffffff")).toBe("#8c8c8c");
  });

  test("returns non-hex colours unchanged", () => {
    expect(dimColor("red", 0.5)).toBe("red");
    expect(dimColor("#fff", 0.5)).toBe("#fff");
  });
});
