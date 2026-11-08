// Tests for the diralias alias-label helpers.

import { describe, expect, test } from "bun:test";
import { formatAliasPath, parseAliasGet } from "./alias-label";

describe("parseAliasGet", () => {
  test("reads an exact match", () => {
    expect(parseAliasGet("dotfiles")).toEqual({ alias: "dotfiles" });
  });

  test("reads a prefix match into alias and remainder", () => {
    // diralias prints "<alias> <remainder>" for a prefix match.
    expect(parseAliasGet("projects dotfiles")).toEqual({
      alias: "projects",
      remainder: "dotfiles",
    });
  });

  test("ignores surrounding whitespace", () => {
    expect(parseAliasGet("  dotfiles\n")).toEqual({ alias: "dotfiles" });
  });

  test("returns nothing for empty output", () => {
    expect(parseAliasGet("")).toBeUndefined();
    expect(parseAliasGet("   \n")).toBeUndefined();
  });
});

describe("formatAliasPath", () => {
  test("renders an exact match as a tilde alias", () => {
    expect(formatAliasPath({ alias: "dotfiles" })).toBe("~dotfiles");
  });

  test("renders a prefix match with the remainder", () => {
    expect(formatAliasPath({ alias: "projects", remainder: "src" })).toBe(
      "~projects/src",
    );
  });
});
