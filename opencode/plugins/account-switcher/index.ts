// Global V2 plugin: server-side entry.
//
// This plugin ships no server behavior.
// The entry exists because OpenCode's directory-plugin discovery loads
// `index.ts` (server) beside the TUI entry (`tui.tsx`).
// All functionality lives in `tui.tsx`.

import { Plugin } from "@opencode/plugin";

export default Plugin.define({
  id: "account-switcher",
  setup() {},
});
