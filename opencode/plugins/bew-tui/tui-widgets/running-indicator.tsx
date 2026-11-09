/** @jsxImportSource @opentui/solid */
// Running indicator widget: the knight-rider sweep while the session runs.
//
// The host shows a running indicator in its own footer while a session works;
// this widget restores it in the region the plugin replaces.
// It owns the running-session condition, so the path and branch widgets stay
// about their own subject.

import { usePlugin } from "@opencode/plugin/tui";
import { Show } from "solid-js";
import { KnightRiderSpinner } from "../tui-toolkit/spinners/components";

// Props for the running indicator.
type RunningIndicatorProps = {
  // Session the indicator describes; absent on the home composer.
  readonly sessionID?: string;
};

// The running sweep, drawn only while the session works.
export function RunningIndicator(props: RunningIndicatorProps) {
  const context = usePlugin();

  // The home composer carries no session, and an idle session is not working.
  const isRunning = () =>
    props.sessionID !== undefined &&
    context.data.session.status(props.sessionID) === "running";

  return (
    <Show when={isRunning()}>
      <KnightRiderSpinner color={context.theme.hue.accent[400]} />
    </Show>
  );
}
