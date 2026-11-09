/** @jsxImportSource @opentui/solid */
// Global V2 TUI plugin: a bundle of widgets for the OpenCode TUI.
//
// A widget owns one topic and lives in `tui-widgets/`: a multi-file widget sits
// under `tui-widgets/<name>/` and always exposes `widget.tsx` as its entrypoint,
// a single-file widget sits directly as `tui-widgets/<name>.tsx`.
// A widget directory holds only what its own topic needs; a piece shared by two
// widgets lives in `tui-toolkit/` instead.
// This entry owns the slot claims: it composes the widgets and wires them to
// the host slot they render into.
//
// Adding a widget means importing its factory, composing it here, claiming the
// slot, and adding its disposer to the cleanup returned below.
// A widget that claims no slot, such as the running indicator, exposes no
// factory; the widget that owns a slot renders it directly.
//
// The plugin can only claim slots the host publishes; it cannot publish new
// slots for other plugins.

import { Plugin } from "@opencode/plugin/tui";
import type { Context } from "@opencode/plugin/tui/context";
import { createDiraliasFooter } from "./tui-widgets/diralias/widget";
import { createGitBranch } from "./tui-widgets/git-branch";
import { RunningIndicator } from "./tui-widgets/running-indicator";
import { createSessionStats } from "./tui-widgets/session-stats/widget";

export default Plugin.define({
  id: "bew-tui.tui",
  setup(context: Context) {
    // Replaces the footer's left region — the location label and the running
    // indicator — with the running sweep, a diralias-aware path label, and a
    // git-branch label.
    // The shared prompt composer renders this slot both in a session and on the
    // home screen, so one claim covers the prompt and home footers.
    // `home.footer.status` is a different region — the home screen's health and
    // version row — not the composer footer.
    const diraliasFooter = createDiraliasFooter();
    const branchLabel = createGitBranch(context);
    const sessionStats = createSessionStats(context);

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
            <RunningIndicator sessionID={input.sessionID} />
            {diraliasFooter.render(input.sessionID)}
            {branchLabel.render(input.sessionID)}
          </box>
        ),
      }),
      // The composer header in a session: message and tool counts for the
      // whole session and for its active context after DCP compression.
      // The wrapper fills the region so the line sits at its right edge.
      context.ui.slot({
        append: "session.composer.top",
        render: (input) => (
          <box flexDirection="row" justifyContent="flex-end" width="100%">
            {sessionStats.render(input.sessionID)}
          </box>
        ),
      }),
    ];

    return () => {
      disposeSlots.forEach((dispose) => dispose());
      diraliasFooter.dispose();
      branchLabel.dispose();
      sessionStats.dispose();
    };
  },
});
