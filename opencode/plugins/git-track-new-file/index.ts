// Global V2 plugin: registers the `git_track_new_file` tool.
//
// Why an explicit tool rather than an auto-hook: a plugin could run
// `git add -N` automatically from a `tool.execute.after` hook. However,
// injecting a confirmation message back into the conversation (even with
// `noReply`) flips OpenCode into plan mode and interrupts the agent's flow.
// An explicit tool keeps the agent in control: it calls the tool, the tool
// runs silently, and control returns immediately.
//
// The companion skill (`skills/git-track-new-file/`) tells the agent when to
// call this tool.

import { Plugin } from "@opencode/plugin";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { realpath } from "node:fs/promises";

const execFileAsync = promisify(execFile);

// Hard-coded secret patterns — safety net regardless of .gitignore.
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
  try {
    return await realpath(filePath);
  } catch {
    return filePath;
  }
}

// Returns true if git would ignore this path (per .gitignore rules).
async function isGitIgnored(filePath: string): Promise<boolean> {
  try {
    await execFileAsync("git", ["check-ignore", "-q", filePath]);
    return true; // exit 0 → path is ignored
  } catch {
    return false; // non-zero (typically exit 1 → not ignored) or git error
  }
}

// Resolve symlinks/relative paths, check gitignore, then run `git add -N`.
// Retries once with the realpath if the first attempt fails with
// "outside repository". Returns true if `git add -N` succeeded.
async function intentAdd(filePath: string): Promise<boolean> {
  if (isSecret(filePath)) return false;

  // Resolve early so the gitignore check and `git add -N` use the real path.
  const real = await resolveReal(filePath);

  if (await isGitIgnored(real)) return false;

  const tryAdd = async (path: string): Promise<{ ok: boolean; outsideRepo: boolean }> => {
    try {
      await execFileAsync("git", ["add", "-N", path]);
      return { ok: true, outsideRepo: false };
    } catch (error) {
      const stderr = (error as { stderr?: string | Buffer }).stderr?.toString() ?? "";
      return { ok: false, outsideRepo: stderr.includes("outside repository") };
    }
  };

  const first = await tryAdd(filePath);
  if (first.ok) return true;

  if (first.outsideRepo && real !== filePath) {
    // Original path was under a symlink — retry with the resolved path.
    const retry = await tryAdd(real);
    if (retry.ok) return true;
  }
  // Failure is non-fatal — the tool continues silently.
  return false;
}

export default Plugin.define({
  id: "git-track-new-file",
  async setup(ctx) {
    await ctx.tool.transform((editor) => {
      editor.add({
        name: "git_track_new_file",
        description:
          "Call this on a newly created file or directory to git-track it for the user (runs `git add -N`). "
          + "Gitignored paths, secrets, and /tmp are skipped automatically. "
          + "See the `git-track-new-file` skill for when to call this and which paths to skip.",
        input: {
          type: "object",
          properties: {
            path: { type: "string", description: "Absolute path to the new file or directory" },
          },
          required: ["path"],
          additionalProperties: false,
        },
        options: { codemode: true },
        async execute(input: { path: string }) {
          await intentAdd(input.path);
          return { content: `git add -N attempted for: ${input.path}` };
        },
      });
    });
  },
});
