// Tests for the git-status helpers.

import { describe, expect, test } from "bun:test";
import { formatBranchParts, parseGitStatus } from "./git-status";

// A clean, in-sync branch: porcelain v2 lists no path lines for unchanged files.
const CLEAN_IN_SYNC = [
  "# branch.oid 0123456789abcdef",
  "# branch.head main",
  "# branch.upstream origin/main",
  "# branch.ab +0 -0",
].join("\n");

describe("parseGitStatus", () => {
  test("reads a clean, in-sync branch", () => {
    expect(parseGitStatus(CLEAN_IN_SYNC)).toEqual({
      dirty: false,
      ahead: 0,
      behind: 0,
    });
  });

  test("counts ahead and behind commits", () => {
    const output = [
      "# branch.head main",
      "# branch.ab +2 -3",
    ].join("\n");
    expect(parseGitStatus(output)).toEqual({
      dirty: false,
      ahead: 2,
      behind: 3,
    });
  });

  test("marks a changed path dirty", () => {
    const output = ["1 .M N... 100644 100644 100644 0 0 file.txt"].join("\n");
    expect(parseGitStatus(output).dirty).toBe(true);
  });

  test("marks an untracked path dirty", () => {
    const output = ["? new.txt"].join("\n");
    expect(parseGitStatus(output).dirty).toBe(true);
  });

  test("leaves counts at zero without an upstream line", () => {
    // A detached or unborn branch prints no `# branch.ab` line.
    const output = ["# branch.head (detached)"].join("\n");
    expect(parseGitStatus(output)).toEqual({
      dirty: false,
      ahead: 0,
      behind: 0,
    });
  });

  test("returns an all-clean status for empty output", () => {
    expect(parseGitStatus("")).toEqual({ dirty: false, ahead: 0, behind: 0 });
  });
});

describe("formatBranchParts", () => {
  test("separates the branch glyph from the name", () => {
    expect(formatBranchParts("main", undefined)).toEqual({
      glyph: "\u{f418}",
      name: "main",
      ahead: "",
      behind: "",
    });
  });

  test("separates the divergence counts", () => {
    expect(
      formatBranchParts("main", { dirty: false, ahead: 1, behind: 2 }),
    ).toEqual({
      glyph: "\u{f418}",
      name: "main",
      ahead: "\u{2191}1",
      behind: "\u{2193}2",
    });
  });

  test("omits a zero count", () => {
    expect(
      formatBranchParts("main", { dirty: true, ahead: 0, behind: 1 }),
    ).toEqual({
      glyph: "\u{f418}",
      name: "main",
      ahead: "",
      behind: "\u{2193}1",
    });
  });
});
