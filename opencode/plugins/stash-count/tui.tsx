/** @jsxImportSource @opentui/solid */
// Global V2 TUI plugin: show how many prompts are in OpenCode's prompt stash.
//
// OpenCode keeps no live API for the prompt stash: the stash is a local JSONL
// file under the state directory, written by the TUI itself.
// The file is shared by every TUI on the machine, but each TUI loads it once at
// startup and then keeps its own in-memory stash. A stash made in another TUI
// therefore never reaches this TUI's list, even though the file changes.
//
// The plugin reads the file for the count and watches its directory, so the
// count follows stash, pop, and delete actions. Visibility comes from the
// host's own `prompt.stash.list` command instead: the host enables it only
// while this TUI's stash is non-empty, so the count hides in TUIs that have
// no stashes of their own and a click always opens a non-empty list.
//
// This split is a provisional reading of host behaviour, not a verified one.
// The installed OpenCode is behind on versions, and the file count can
// overstate this TUI's stash: two TUIs with one stash each both show
// "Stash: 2". Revisit once the host confirms or exposes a per-client stash
// source: ../../TASK-20261023T2345-stash-count-per-client-detection-after-upgrade.md
//
// The count renders in the prompt footer and on the home screen, and opens the
// host stash list on click.

import { Plugin, usePlugin } from "@opencode/plugin/tui";
import type { Context, KeymapCommand } from "@opencode/plugin/tui/context";
import { TextAttributes } from "@opentui/core";
import { readFileSync, watch } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { createSignal, Show } from "solid-js";

// Host command that opens the built-in stash list.
// The plugin dispatches it from the count, so the host owns the list UI.
const STASH_LIST_COMMAND = "prompt.stash.list";

// OpenCode keeps only the newest stash entries, so the count mirrors that cap
// instead of reporting orphaned lines from an oversized file.
const MAX_STASH_ENTRIES = 50;

// Milliseconds to wait after a file event before re-reading, so a write that
// fires several events settles before the count is recomputed.
const REFRESH_DEBOUNCE_MS = 50;

// Wire shape of one prompt-stash JSONL line, limited to the fields used to
// decide whether the line is a real stash entry.
type StashRecord = {
  prompt: unknown;
  timestamp: number;
};

// Resolve OpenCode's state directory the same way the host does.
function getStateDirectory(): string {
  const stateRoot =
    process.env.XDG_STATE_HOME ?? join(homedir(), ".local", "state");
  return join(stateRoot, "opencode");
}

// Parse the stash file and count valid entries.
// A missing or unreadable file means an empty stash.
function countStashedPrompts(stashPath: string): number {
  let contents: string;
  try {
    contents = readFileSync(stashPath, "utf8");
  } catch {
    return 0;
  }

  const validEntries = contents
    .split("\n")
    .filter((line) => line.trim() !== "")
    .filter(isStashRecord);

  return Math.min(validEntries.length, MAX_STASH_ENTRIES);
}

// Narrow one JSONL line to a stash record.
// Malformed lines are ignored, matching the host's own loader.
function isStashRecord(line: string): boolean {
  let parsed: unknown;
  try {
    parsed = JSON.parse(line);
  } catch {
    return false;
  }

  if (typeof parsed !== "object" || parsed === null) {
    return false;
  }

  const record = parsed as Partial<StashRecord>;
  return (
    typeof record.prompt === "object" &&
    record.prompt !== null &&
    typeof record.timestamp === "number"
  );
}

// Whether a command is enabled.
// A host may list disabled commands or leave them out of `commands()`, and
// `enabled` can be a boolean or a getter, so accept every shape.
function isCommandEnabled(enabled: KeymapCommand["enabled"]): boolean {
  return typeof enabled === "function" ? enabled() : enabled !== false;
}

// Status line showing the stash count.
// Renders only while this TUI has a stash of its own, which the host exposes
// by enabling the stash list command.
function StashCount(props: { count: number }) {
  const context = usePlugin();
  const [isHovered, setIsHovered] = createSignal(false);
  const hasStash = () =>
    context.keymap
      .commands()
      .some(
        (command) =>
          command.id === STASH_LIST_COMMAND &&
          isCommandEnabled(command.enabled),
      );
  // Not every theme defines the yellow hue palette, so fall back to the
  // terminal's named yellow instead of dereferencing a missing palette.
  const defaultColor = context.theme.hue.yellow?.[400] ?? "yellow";

  return (
    <Show when={hasStash()}>
      <text
        fg={isHovered() ? "white" : defaultColor}
        attributes={TextAttributes.BOLD}
        selectable={false}
        onMouseOver={() => setIsHovered(true)}
        onMouseOut={() => setIsHovered(false)}
        onMouseUp={(event) => {
          if (event.button !== 0) {
            return;
          }
          event.stopPropagation();
          // The host enables this command only while this TUI's stash is
          // non-empty, which is the same condition that renders this text.
          context.keymap.dispatch(STASH_LIST_COMMAND);
        }}
      >{props.count > 0 ? `Stash: ${props.count}` : "Stash"}</text>
    </Show>
  );
}

export default Plugin.define({
  id: "stash-count.tui",
  setup(context: Context) {
    const stashPath = join(getStateDirectory(), "prompt-stash.jsonl");
    const [count, setCount] = createSignal(countStashedPrompts(stashPath));

    // Debounced refresh shared by every file event.
    let refreshTimer: ReturnType<typeof setTimeout> | undefined;
    function scheduleRefresh(): void {
      if (refreshTimer !== undefined) {
        clearTimeout(refreshTimer);
      }
      refreshTimer = setTimeout(() => {
        setCount(countStashedPrompts(stashPath));
      }, REFRESH_DEBOUNCE_MS);
    }

    // Watch the directory, not the file: OpenCode rewrites the file in place on
    // pop and delete, which can replace the watched inode.
    let watcher: ReturnType<typeof watch> | undefined;
    try {
      watcher = watch(getStateDirectory(), (_event, filename) => {
        const changedFile = filename === null ? "" : String(filename);
        if (changedFile === "prompt-stash.jsonl") {
          scheduleRefresh();
        }
      });
    } catch {
      // The state directory may not exist yet on a brand-new install.
      // The initial count is still correct; a later restart picks up the file.
    }

    const render = () => <StashCount count={count()} />;
    const disposers: Array<() => void> = [
      context.ui.slot({
        append: "home.footer.status",
        render,
      }),
      context.ui.slot({
        append: "prompt.footer.status",
        render,
      }),
    ];

    return () => {
      if (refreshTimer !== undefined) {
        clearTimeout(refreshTimer);
      }
      watcher?.close();
      for (const dispose of disposers) {
        dispose();
      }
    };
  },
});
