// Core git-tracking logic for the `git-track-new-file` plugin.
// Kept separate from `index.ts` (plugin registration) so it is unit-testable.

import { execFile } from "node:child_process";
import { promisify } from "node:util";
import path from "node:path";

const execFileAsync = promisify(execFile);

// Hard-coded secret patterns — safety net regardless of .gitignore.
const SECRET_PATTERNS: Array<(p: string) => boolean> = [
  (p) => p.startsWith("/tmp/"),
  (p) => /\.(secret|key|pem|p12|pfx)$/.test(p),
  (p) => /\/(\.env(\.[^/]+)?)$/.test(p),
];

// Outcome of an `intentAdd` attempt.
export type AddResult =
  | { readonly status: "tracked" }
  | { readonly status: "skipped"; readonly reason: "gitignored" }
  | { readonly status: "failed"; readonly detail: string };

// Outcome of a `trackNewPath` attempt: `AddResult` plus the secret-path skip.
export type TrackResult = AddResult | { readonly status: "skipped"; readonly reason: "secret" };

// Returns true when `filePath` matches a hard-coded secret pattern.
export function isSecret(filePath: string): boolean {
  return SECRET_PATTERNS.some((fn) => fn(filePath));
}

// Returns true when git would ignore `filePath` per .gitignore rules.
// Anchored with `git -C <dir>` so repo discovery does not depend on the process cwd.
export async function isGitIgnored(filePath: string): Promise<boolean> {
  try {
    await execFileAsync("git", ["-C", path.dirname(filePath), "check-ignore", "-q", filePath]);
    return true; // exit 0 → path is ignored
  } catch {
    return false; // non-zero (typically exit 1 → not ignored) or git error
  }
}

// Intents-to-add `filePath` with `git add -N`, anchored at the file's own
// directory so repo discovery does not depend on the process cwd (V2 runs
// plugins in a shared process whose cwd is not the session project).
// Returns the outcome; failures carry the git stderr detail.
export async function intentAdd(filePath: string): Promise<AddResult> {
  if (await isGitIgnored(filePath)) return { status: "skipped", reason: "gitignored" };

  try {
    await execFileAsync("git", ["-C", path.dirname(filePath), "add", "-N", filePath]);
    return { status: "tracked" };
  } catch (error) {
    const stderr = (error as { stderr?: string | Buffer }).stderr?.toString() ?? "";
    return { status: "failed", detail: stderr.trim().split("\n")[0] || "git add -N failed" };
  }
}

// Applies the secret-path guard, then intents-to-add `filePath` with git.
export async function trackNewPath(filePath: string): Promise<TrackResult> {
  if (isSecret(filePath)) return { status: "skipped", reason: "secret" };
  return intentAdd(filePath);
}

// Renders `filePath` as `<repo>/<path-relative-to-repo-root>`, with the literal
// `<repo>` token keeping output independent of the repo location.
// `--show-prefix` (from the file's directory) reports the repo-relative
// location even through symlinked paths. Falls back to the input path when
// `filePath` is not inside a git repository.
export async function formatRepoPath(filePath: string): Promise<string> {
  try {
    const { stdout } = await execFileAsync("git", ["-C", path.dirname(filePath), "rev-parse", "--show-prefix"]);
    return path.posix.join("<repo>", stdout.trim(), path.basename(filePath));
  } catch {
    return filePath;
  }
}

// Short one-line outcome for the tool result.
export function formatTrackResult(displayPath: string, result: TrackResult): string {
  switch (result.status) {
    case "tracked":
      return `tracked: ${displayPath}`;
    case "skipped":
      return `skipped: ${displayPath} (${result.reason})`;
    case "failed":
      return `failed: ${displayPath} (${result.detail})`;
  }
}
