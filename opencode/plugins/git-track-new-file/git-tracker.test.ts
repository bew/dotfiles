// Unit tests for the `git-track-new-file` plugin's core logic (`git-tracker.ts`).
// Uses real git repositories under a temp dir — no mocks.

import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { execFile } from "node:child_process";
import { mkdir, mkdtemp, rm, symlink, writeFile } from "node:fs/promises";
import { promisify } from "node:util";
import os from "node:os";
import path from "node:path";

import {
  formatRepoPath,
  formatTrackResult,
  intentAdd,
  isGitIgnored,
  isSecret,
  trackNewPath,
} from "./git-tracker";

const execFileAsync = promisify(execFile);

let workspace = "";
let repo = "";
let nonRepo = "";
let link = "";

// Builds the suite workspace outside `/tmp`, because `isSecret` skips `/tmp/`
// paths and that would defeat the tracked-path assertions.
async function makeWorkspace(): Promise<string> {
  const tmp = os.tmpdir();
  const base = tmp === "/tmp" || tmp.startsWith("/tmp/") ? "/var/tmp" : tmp;
  await mkdir(base, { recursive: true });
  return mkdtemp(path.join(base, "git-tracker-test-"));
}

// Runs a git command in `cwd`, rejecting on non-zero exit.
async function runGit(args: string[], cwd: string): Promise<void> {
  await execFileAsync("git", args, { cwd });
}

// Captures stdout of a git command in `cwd`.
async function gitStdout(args: string[], cwd: string): Promise<string> {
  return (await execFileAsync("git", args, { cwd })).stdout;
}

beforeAll(async () => {
  workspace = await makeWorkspace();
  repo = path.join(workspace, "repo");
  nonRepo = path.join(workspace, "nonrepo");
  link = path.join(workspace, "linkrepo");

  await mkdir(path.join(repo, "sub", "deep"), { recursive: true });
  await mkdir(nonRepo, { recursive: true });
  await runGit(["init", "-q"], repo);

  await writeFile(path.join(repo, "top.md"), "top\n");
  await writeFile(path.join(repo, "sub", "deep", "f.md"), "nested\n");
  await writeFile(path.join(repo, "ign.md"), "ignored\n");
  await writeFile(path.join(repo, ".gitignore"), "ign.md\n");
  await writeFile(path.join(nonRepo, "loose.md"), "loose\n");

  // A symlinked repo path exercises `--show-prefix` repo-root resolution.
  await symlink(repo, link, "dir");
  await writeFile(path.join(link, "sub", "deep", "sym.md"), "sym\n");
});

afterAll(async () => {
  await rm(workspace, { recursive: true, force: true });
});

describe("isSecret", () => {
  test("skips /tmp paths", () => {
    expect(isSecret("/tmp/foo.md")).toBe(true);
  });

  test("skips secret-suffixed files", () => {
    expect(isSecret("/home/x/id_rsa.key")).toBe(true);
    expect(isSecret("/home/x/cert.pem")).toBe(true);
  });

  test("skips .env files", () => {
    expect(isSecret("/home/x/.env")).toBe(true);
    expect(isSecret("/home/x/.env.local")).toBe(true);
  });

  test("allows ordinary paths", () => {
    expect(isSecret("/home/x/notes.md")).toBe(false);
    expect(isSecret("/home/x/env.md")).toBe(false);
  });
});

describe("isGitIgnored", () => {
  test("detects a gitignored path", async () => {
    expect(await isGitIgnored(path.join(repo, "ign.md"))).toBe(true);
  });

  test("returns false for a normal path", async () => {
    expect(await isGitIgnored(path.join(repo, "top.md"))).toBe(false);
  });
});

describe("intentAdd", () => {
  test("tracks a new file in a repo", async () => {
    const file = path.join(repo, "top.md");
    expect(await intentAdd(file)).toEqual({ status: "tracked" });
    expect(await gitStdout(["status", "--short", "top.md"], repo)).toContain("A");
  });

  test("skips a gitignored file", async () => {
    expect(await intentAdd(path.join(repo, "ign.md"))).toEqual({ status: "skipped", reason: "gitignored" });
  });

  test("fails outside a repository with the git error", async () => {
    const result = await intentAdd(path.join(nonRepo, "loose.md"));
    expect(result.status).toBe("failed");
    if (result.status === "failed") expect(result.detail).toContain("not a git repository");
  });
});

describe("trackNewPath", () => {
  test("skips secret paths before touching git", async () => {
    expect(await trackNewPath("/tmp/secret-plan.md")).toEqual({ status: "skipped", reason: "secret" });
  });

  test("delegates ordinary paths to intentAdd", async () => {
    expect(await trackNewPath(path.join(repo, "sub", "deep", "f.md"))).toEqual({ status: "tracked" });
  });
});

describe("formatRepoPath", () => {
  test("renders a repo-root file", async () => {
    expect(await formatRepoPath(path.join(repo, "top.md"))).toBe("<repo>/top.md");
  });

  test("renders a nested file", async () => {
    expect(await formatRepoPath(path.join(repo, "sub", "deep", "f.md"))).toBe("<repo>/sub/deep/f.md");
  });

  test("resolves a symlinked repo path", async () => {
    expect(await formatRepoPath(path.join(link, "sub", "deep", "sym.md"))).toBe("<repo>/sub/deep/sym.md");
  });

  test("falls back to the input path outside a repo", async () => {
    const loose = path.join(nonRepo, "loose.md");
    expect(await formatRepoPath(loose)).toBe(loose);
  });
});

describe("formatTrackResult", () => {
  test("renders each outcome", () => {
    expect(formatTrackResult("<repo>/a.md", { status: "tracked" })).toBe("tracked: <repo>/a.md");
    expect(formatTrackResult("<repo>/a.md", { status: "skipped", reason: "gitignored" })).toBe(
      "skipped: <repo>/a.md (gitignored)",
    );
    expect(formatTrackResult("<repo>/a.md", { status: "failed", detail: "boom" })).toBe(
      "failed: <repo>/a.md (boom)",
    );
  });
});
