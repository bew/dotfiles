/** @jsxImportSource @opentui/solid */
// Git-branch footer component: the branch label beside the directory path.
//
// Draws the branch glyph in the repository orange and the branch name in the
// default foreground, turning warning-coloured when the tree is dirty; the
// ahead count shows in a dark orange and the behind count in error, with a
// small braille loader while a slow `git status` runs.
// The status comes from `git status --porcelain=v2 --branch`, re-run whenever
// the directory or branch changes and on the adaptive poll in `lib/git-watcher`.

import { usePlugin } from "@opencode/plugin/tui";
import type { Context } from "@opencode/plugin/tui/context";
import type { ColorInput } from "@opentui/core";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { Show, createEffect, createSignal, on, onCleanup } from "solid-js";
import type { JSX } from "solid-js";
import { createGitWatcher } from "../lib/git-watcher";
import { formatBranchParts, parseGitStatus } from "../lib/git-status";
import type { GitStatus } from "../lib/git-status";
import { BrailleSpinner } from "../tui-toolkit/spinners/components";

// `execFile` bound to a promise for the one-off `git status` calls.
const execFileAsync = promisify(execFile);

// Milliseconds before a `git status` call is abandoned; a hung git must never
// stall the footer.
const GIT_TIMEOUT_MS = 2000;

// Milliseconds a `git status` run may take before the loader appears.
const SLOW_STATUS_MS = 1000;

// The ahead count's colour: a dark orange, a shade below the branch glyph
// orange. No theme token carries this shade, so it stays fixed.
const AHEAD_COLOR = "#cf6a1e";

// The branch label, ready to plug into the footer row.
export type GitBranchLabel = {
  // Render the label; `sessionID` is absent on the home composer, whose own
  // slot carries no session.
  readonly render: (sessionID: string | undefined) => JSX.Element;
  // Stop the status poller and its activity subscription.
  readonly dispose: () => void;
};

// Build the branch label and start the adaptive status poller.
//
// The poller is owned by the plugin rather than the rendered component, so it
// starts once and survives any re-render of the slot.
export function createGitBranch(context: Context): GitBranchLabel {
  // Bumped on every poll, so the label re-runs git status.
  const [tick, setTick] = createSignal(0);

  const watcher = createGitWatcher({
    onTick: () => setTick((value) => value + 1),
    subscribeActivity: (onActivity) => context.data.listen(() => onActivity()),
    // A session in the labelled directory keeps the poll at the floor.
    hasRunningSession: (directory) =>
      context.data.session
        .list()
        .some(
          (session) =>
            session.location?.directory === directory &&
            context.data.session.status(session.id) === "running",
        ),
  });

  return {
    render: (sessionID) => (
      <GitBranchStatus
        sessionID={sessionID}
        tick={tick()}
        onDirectoryChange={(directory) => watcher.setDirectory(directory)}
        onStatusResolved={(directory, signature) =>
          watcher.reportStatus(directory, signature)
        }
      />
    ),
    dispose: () => watcher.dispose(),
  };
}

// The branch label: the branch glyph, name, and divergence, plus a loader while
// a slow status run is in flight.
function GitBranchStatus(props: {
  readonly sessionID?: string;
  readonly tick: number;
  // Reports the directory the label now describes to the poller.
  readonly onDirectoryChange: (directory: string | undefined) => void;
  // Reports the signature of a resolved status to the poller.
  readonly onStatusResolved: (directory: string, signature: string) => void;
}) {
  const context = usePlugin();
  const [status, setStatus] = createSignal<GitStatus | undefined>(undefined);
  const [slow, setSlow] = createSignal(false);

  // Location this label describes: the session's own, or the app-wide one for
  // the home composer, which has no session.
  const location = () =>
    props.sessionID === undefined
      ? context.location ?? context.data.location.default()
      : context.data.session.get(props.sessionID)?.location;

  const directory = () => location()?.directory;

  const branchName = () => {
    const current = location();
    if (current === undefined) {
      return undefined;
    }
    return context.data.location.vcs.info(current)?.branch.current;
  };

  // Publish the directory so the poller scopes its runs to it.
  createEffect(on(() => directory(), (dir) => props.onDirectoryChange(dir)));

  // Re-run git status whenever the directory, the branch, or the poll moves.
  createEffect(
    on(
      () => [directory(), props.tick, branchName()] as const,
      ([dir, , name]) => {
        setSlow(false);
        if (dir === undefined) {
          setStatus(undefined);
          return;
        }
        // Report an empty status without a branch, so a non-repository
        // directory still backs the poller off instead of polling forever.
        if (name === undefined) {
          setStatus(undefined);
          props.onStatusResolved(dir, statusSignature(undefined));
          return;
        }
        let active = true;
        const slowTimer = setTimeout(() => setSlow(true), SLOW_STATUS_MS);
        void resolveGitStatus(dir).then((resolved) => {
          if (!active) {
            return;
          }
          clearTimeout(slowTimer);
          setSlow(false);
          setStatus(resolved);
          props.onStatusResolved(dir, statusSignature(resolved));
        });
        onCleanup(() => {
          active = false;
          clearTimeout(slowTimer);
        });
      },
    ),
  );

  return (
    <Show when={branchName()}>
      {(name) => {
        const parts = () => formatBranchParts(name(), status());
        return (
          <box flexDirection="row" gap={1} flexShrink={0}>
            <Show when={slow()}>
              <BrailleSpinner color={glyphColor(context)} />
            </Show>
            <text
              fg={glyphColor(context)}
              selectable={false}
              wrapMode="none"
              truncate
              flexShrink={0}
            >
              {parts().glyph}
            </text>
            <text
              fg={nameColor(context, status())}
              wrapMode="none"
              truncate
              flexShrink={0}
            >
              {parts().name}
            </text>
            <Show when={parts().ahead !== ""}>
              <text
                fg={AHEAD_COLOR}
                selectable={false}
                wrapMode="none"
                truncate
                flexShrink={0}
              >
                {parts().ahead}
              </text>
            </Show>
            <Show when={parts().behind !== ""}>
              <text
                fg={context.theme.text.feedback.error.base}
                selectable={false}
                wrapMode="none"
                truncate
                flexShrink={0}
              >
                {parts().behind}
              </text>
            </Show>
          </box>
        );
      }}
    </Show>
  );
}

// Signature the poller diffs to detect a status change.
function statusSignature(status: GitStatus | undefined): string {
  if (status === undefined) {
    return "none";
  }
  return `${status.dirty ? "dirty" : "clean"}:${status.ahead}:${status.behind}`;
}

// The branch glyph's colour: the repository glyph orange, so both git glyphs
// match.
function glyphColor(context: Context): ColorInput {
  return context.theme.hue.orange?.[400] ?? "#ff8700";
}

// The branch name's colour, from the working-tree status: warning when the tree
// is dirty, the default foreground otherwise.
function nameColor(
  context: Context,
  status: GitStatus | undefined,
): ColorInput {
  if (status?.dirty === true) {
    return context.theme.text.feedback.warning.base;
  }
  return context.theme.text.base;
}

// Resolve a directory to its git status by running `git status`.
// A non-repository directory and a failure both yield no status, so the caller
// falls back to the branch name alone.
async function resolveGitStatus(
  directory: string,
): Promise<GitStatus | undefined> {
  try {
    const { stdout } = await execFileAsync(
      "git",
      ["status", "--porcelain=v2", "--branch"],
      { cwd: directory, timeout: GIT_TIMEOUT_MS },
    );
    return parseGitStatus(stdout);
  } catch {
    return undefined;
  }
}
