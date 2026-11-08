/** @jsxImportSource @opentui/solid */
// Global V2 TUI plugin: a bundle of widgets for the OpenCode TUI.
//
// Each component owns its own logic: a multi-file component lives under
// `components/<name>/`, a single-file one sits directly as `components/<name>.tsx`.
// This entry owns the slot claims: it composes the components and wires them to
// the host slot they render into.
//
// Adding a widget means importing its factory, composing it here, claiming the
// slot, and adding its disposer to the cleanup returned below.
// A component that claims no slot, such as the spinner, exposes no factory; the
// widget that owns a slot renders it directly.
//
// The plugin can only claim slots the host publishes; it cannot publish new
// slots for other plugins.

import { Plugin } from "@opencode/plugin/tui";
import type { Context } from "@opencode/plugin/tui/context";
import { createDiraliasFooter } from "./components/diralias/footer-status";
import { createGitBranch } from "./components/git-branch";

export default Plugin.define({
  id: "bew-tui.tui",
  setup(context: Context) {
    // Replaces the footer's left region — the location label and the running
    // spinner — with a diralias-aware path label and a git-branch label.
    // The shared prompt composer renders this slot both in a session and on the
    // home screen, so one claim covers the prompt and home footers.
    // `home.footer.status` is a different region — the home screen's health and
    // version row — not the composer footer.
    const diraliasFooter = createDiraliasFooter();
    const branchLabel = createGitBranch(context);

    const disposeSlots = [
      context.ui.slot({
        replace: "prompt.footer.status",
        render: (input) => (
          <box
            flexDirection="row"
            // Two cells separate the path label from the branch label.
            gap={2}
            flexGrow={1}
            flexShrink={1}
            minWidth={0}
          >
            {diraliasFooter.render(input.sessionID)}
            {branchLabel.render(input.sessionID)}
          </box>
        ),
      }),
    ];

    return () => {
      disposeSlots.forEach((dispose) => dispose());
      diraliasFooter.dispose();
      branchLabel.dispose();
    };
  },
});
