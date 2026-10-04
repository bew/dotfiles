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
import { formatRepoPath, formatTrackResult, trackNewPath } from "./git-tracker";

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
        output: { type: "string", description: "One-line tracking status" },
        options: { codemode: true },
        async execute(input: { path: string }) {
          const [result, displayPath] = await Promise.all([
            trackNewPath(input.path),
            formatRepoPath(input.path),
          ]);
          return { output: formatTrackResult(displayPath, result) };
        },
      });
    });
  },
});
