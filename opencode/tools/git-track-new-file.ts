// Global tool: git-tracks new files created via any tool call.
//
// All skip heuristics and retry logic live here.
// The companion skill (git-track-new-file) tells the agent when to call this tool.

import { tool } from "@opencode-ai/plugin";
import { $ } from "bun";

// Hard-coded secrets patterns — safety net regardless of .gitignore.
const SECRET_PATTERNS: Array<(p: string) => boolean> = [
  (p) => p.startsWith("/tmp/"),
  (p) => /\.(secret|key|pem|p12|pfx)$/.test(p),
  (p) => /\/(\.env(\.[^/]+)?)$/.test(p),
];

function isSecret(filePath: string): boolean {
  return SECRET_PATTERNS.some((fn) => fn(filePath));
}

// Resolve a path to its real on-disk path (follows symlinks).
async function resolveReal(filePath: string): Promise<string> {
  const resolved = (await $`realpath ${filePath}`.quiet().nothrow().text()).trim();
  return resolved || filePath;
}

// Returns true if git would ignore this path (per .gitignore rules).
async function isGitIgnored(filePath: string): Promise<boolean> {
  const result = await $`git check-ignore -q ${filePath}`.quiet().nothrow();
  return result.exitCode === 0;
}

// Resolve symlinks/relative paths, check gitignore, then run `git add -N`.
// Retries once with realpath if the first attempt fails with "outside repository".
// Returns true if `git add -N` succeeded, false if skipped or failed.
async function intentAdd(filePath: string): Promise<boolean> {
  if (isSecret(filePath)) return false;

  // Resolve early so gitignore check and git add -N operate on the real path.
  const real = await resolveReal(filePath);

  if (await isGitIgnored(real)) return false;

  const tryAdd = async (path: string): Promise<{ ok: boolean; outsideRepo: boolean }> => {
    const result = await $`git add -N ${path}`.quiet().nothrow();
    const ok = result.exitCode === 0;
    const outsideRepo = !ok && result.stderr.toString().includes("outside repository");
    return { ok, outsideRepo };
  };

  const first = await tryAdd(filePath);
  if (first.ok) return true;

  if (first.outsideRepo && real !== filePath) {
    // Original path was under a symlink — retry with resolved path.
    const retry = await tryAdd(real);
    if (retry.ok) return true;
  }
  // Failure is non-fatal — tool continues silently.
  return false;
}

export default tool({
  description:
    "ALWAYS call this after creating any new file or directory in the repository — "
    + "whether via `write`, `bash` (cp, mv, curl -o, mkdir, tar, unzip), or any other tool. "
    + "Runs `git add -N` so the file is git-tracked for the user immediately. "
    + "Skips gitignored paths, secrets, and /tmp automatically.",
  args: {
    path: tool.schema.string().describe("Absolute path to the new file or directory"),
  },
  async execute(args) {
    await intentAdd(args.path);
    return `git add -N attempted for: ${args.path}`;
  },
});
