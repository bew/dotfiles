// Tests for the git-repository location helpers.

import { describe, expect, test } from "bun:test";
import { parseRepoLocation } from "./git-repo";

describe("parseRepoLocation", () => {
  test("reads the root and a subdirectory suffix", () => {
    expect(
      parseRepoLocation("/home/x/dotfiles\nopencode/plugins/bew-tui/\n"),
    ).toEqual({ root: "/home/x/dotfiles", suffix: "opencode/plugins/bew-tui" });
  });

  test("reads an empty suffix at the repository root", () => {
    expect(parseRepoLocation("/home/x/dotfiles\n\n")).toEqual({
      root: "/home/x/dotfiles",
      suffix: "",
    });
  });

  test("reads an empty suffix without a second line", () => {
    expect(parseRepoLocation("/home/x/dotfiles\n")).toEqual({
      root: "/home/x/dotfiles",
      suffix: "",
    });
  });

  test("returns nothing outside a repository", () => {
    expect(parseRepoLocation("")).toBeUndefined();
    expect(parseRepoLocation("\n")).toBeUndefined();
  });
});
