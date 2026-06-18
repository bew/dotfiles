// This file is auto-loaded by OpenCode as a server-side plugin.
// It lives in ~/.config/opencode/plugins/ and is automatically picked up on startup.
//
// It registers a custom "retitle_session" tool that the LLM can invoke.
// The tool is triggered by the /retitle custom command (commands/retitle.md),
// which tells the LLM to generate a good title from the conversation and
// then call this tool to persist it.

import { type Plugin, tool } from "@opencode-ai/plugin";

// `client` is an HTTP client connected to this OpenCode server instance.
// It can call the same REST API endpoints that the TUI and CLI use.
export const Retitle: Plugin = async ({ client }) => {
  return {
    // Tools registered here become available to the LLM alongside built-in tools
    // (read, write, bash, glob, grep, etc.). They are surfaced to every session.
    tool: {
      retitle_session: tool({
        description:
          "Set a new title for the current session. "
          + "Call this tool AFTER you have determined a good title "
          + "from the conversation context.",
        // Zod schema defining the tool's arguments (shown to the LLM):
        args: {
          title: tool.schema.string().describe(
            "New session title (max 80 chars, concise)",
          ),
        },
        // Called when the LLM invokes this tool.
        // `args` contains the argument values provided by the LLM.
        // `context` provides metadata (sessionID, directory, etc.).
        async execute(args, context) {
          // Persist the new title via the session update REST endpoint.
          // This is the same API call the TUI's "session_rename" keybind uses.
          await client.session.update({
            path: { id: context.sessionID },
            body: { title: args.title },
          });
          return `Session title updated to "${args.title}"`;
        },
      }),
    },
  };
};
