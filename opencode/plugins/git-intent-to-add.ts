// Auto-loaded global plugin: registers git intent-to-add behavior.
//
// Two responsibilities:
// 1. Automatically runs `git add -N` after every `write` tool call (no agent involvement needed).
// 2. Exposes a `git_intent_to_add` tool the agent can call for files created via bash commands.
//
// All skip heuristics and retry logic live here — the companion skill only tells the agent
// when to call the tool, not how the logic works.

import { type Plugin, tool } from "@opencode-ai/plugin";
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
  // Failure is non-fatal — plugin continues silently.
  return false;
}

export const GitIntentToAdd: Plugin = async ({ client, worktree }) => {
  return {
    // Automatically intent-add files created by the `write` tool.
    // Injects a short message into the conversation on success (noReply: agent sees it, AI does not respond).
    "tool.execute.after": async (input, _output) => {
      if (input.tool !== "write") return;
      const filePath = (input.args as { filePath?: string }).filePath;
      if (!filePath) return;
      const added = await intentAdd(filePath);
      if (added) {
        const rel = filePath.startsWith(worktree + "/")
          ? filePath.slice(worktree.length + 1)
          : filePath;
        await client.session.prompt({
          path: { id: input.sessionID },
          body: {
            noReply: true,
            parts: [{ type: "text", text: `[git-intent-to-add] File '${rel}' is now git tracked` }],
          },
        });
      }
    },

    // Expose a tool the agent can call for bash-created files.
    tool: {
      git_intent_to_add: tool({
        description:
          "Register a new file or directory with git using intent-to-add (`git add -N`), "
          + "so it appears in `git diff` and other git-aware tools immediately. "
          + "Call this after any bash command that creates new files in the repository "
          + "(e.g. cp, mv, curl -o, mkdir). "
          + "Skips gitignored paths, secrets, and /tmp automatically.",
        args: {
          path: tool.schema.string().describe("Absolute path to the new file or directory"),
        },
        async execute(args) {
          await intentAdd(args.path);
          return `git add -N attempted for: ${args.path}`;
        },
      }),
    },
  };
};
