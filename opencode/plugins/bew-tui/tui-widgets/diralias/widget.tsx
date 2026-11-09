/** @jsxImportSource @opentui/solid */
// Diralias footer widget: the current directory's label.
//
// Outside a repository the label is the directory's diralias alias, so a deep
// directory reads as `~alias`; inside a repository the repository glyph replaces
// the folder glyph, the repository root is shown in the accent colour, and the
// path within the repository follows in the base colour.
// The shared prompt composer renders the replaced `prompt.footer.status` region
// both in a session and on the home screen, so one claim covers both footers;
// the TUI entry composes this widget with the running indicator and the branch
// label in that region.
// Aliases come from `diralias get`, re-run whenever the directory or diralias's
// alias set changes; the repository root comes from `git rev-parse`.

import { usePlugin } from "@opencode/plugin/tui";
import type { Context } from "@opencode/plugin/tui/context";
import { execFile } from "node:child_process";
import { watch } from "node:fs";
import { promisify } from "node:util";
import { Show, createEffect, createSignal, on, onCleanup } from "solid-js";
import type { JSX } from "solid-js";
import { parseRepoLocation } from "../../lib/git-repo";
import type { RepoLocation } from "../../lib/git-repo";
import {
  FOLDER_GLYPH,
  REPO_GLYPH,
  formatAliasPath,
  getDiraliasStateDirectory,
  parseAliasGet,
} from "./alias-label";
import type { AliasMatch } from "./alias-label";

// `execFile` bound to a promise for the one-off `diralias get` calls.
const execFileAsync = promisify(execFile);

// diralias's change marker, bumped on every alias change.
const TICK_FILENAME = "change-tick";

// Milliseconds to wait after a change-tick event before re-resolving, so a
// burst of writes settles first.
const TICK_DEBOUNCE_MS = 50;

// Milliseconds before a `diralias get` or `git rev-parse` call is abandoned; a
// hung or missing binary must never stall the footer.
const GET_TIMEOUT_MS = 2000;

// The directory path split for display: the glyph, the part shown in the
// accent colour, and the in-repository suffix shown in the base colour.
type PathDisplay = {
  // Whether the directory sits inside a repository.
  readonly inRepo: boolean;
  // The alias or abbreviated label of the repository root (or of the directory
  // itself outside a repository).
  readonly baseLabel: string;
  // The path within the repository, empty outside one and at its root.
  readonly suffix: string;
};

// The diralias widget, ready to plug into the footer row.
export type DiraliasFooter = {
  // Render the directory label; `sessionID` is absent on the home composer,
  // whose own slot carries no session.
  readonly render: (sessionID: string | undefined) => JSX.Element;
  // Stop watching diralias for alias changes.
  readonly dispose: () => void;
};

// Build the footer and start watching diralias for alias changes.
//
// The watch is owned by the plugin rather than the rendered component, so it is
// started once and survives any re-render of the slot.
export function createDiraliasFooter(): DiraliasFooter {
  // Bumped whenever diralias changes its alias set, so the footer re-resolves.
  const [aliasTick, setAliasTick] = createSignal(0);
  const stopWatching = watchAliasChanges(() =>
    setAliasTick((value) => value + 1),
  );

  return {
    render: (sessionID) => (
      <DiraliasFooterStatus sessionID={sessionID} aliasTick={aliasTick()} />
    ),
    dispose: stopWatching,
  };
}

// Watch diralias's state directory for alias changes, reporting to `onChange`
// once a burst of writes settles. Returns a disposer that closes the watch.
function watchAliasChanges(onChange: () => void): () => void {
  let debounceTimer: ReturnType<typeof setTimeout> | undefined;
  function scheduleChange(): void {
    if (debounceTimer !== undefined) {
      clearTimeout(debounceTimer);
    }
    debounceTimer = setTimeout(onChange, TICK_DEBOUNCE_MS);
  }

  // Watch the directory, not the tick file: the tick is rewritten in place,
  // which can replace the watched inode.
  let watcher: ReturnType<typeof watch> | undefined;
  try {
    watcher = watch(getDiraliasStateDirectory(), (_event, filename) => {
      if (filename === null || String(filename) === TICK_FILENAME) {
        scheduleChange();
      }
    });
  } catch {
    // diralias may not have created its state directory yet; the footer still
    // resolves on the next directory change or restart.
  }

  return () => {
    if (debounceTimer !== undefined) {
      clearTimeout(debounceTimer);
    }
    watcher?.close();
  };
}

// Resolve a directory to its alias by running `diralias get`.
// No match (non-zero exit) and failure (missing binary) both yield no match, so
// the caller falls back to the abbreviated path.
async function resolveAliasMatch(
  directory: string,
): Promise<AliasMatch | undefined> {
  try {
    const { stdout } = await execFileAsync("diralias", ["get", directory], {
      timeout: GET_TIMEOUT_MS,
    });
    return parseAliasGet(stdout);
  } catch {
    return undefined;
  }
}

// Resolve a directory to its repository root and path within it by running
// `git rev-parse`. A non-repository directory and a failure both yield no
// location, so the caller falls back to the plain directory label.
async function resolveRepoLocation(
  directory: string,
): Promise<RepoLocation | undefined> {
  try {
    const { stdout } = await execFileAsync(
      "git",
      ["rev-parse", "--show-toplevel", "--show-prefix"],
      { cwd: directory, timeout: GET_TIMEOUT_MS },
    );
    return parseRepoLocation(stdout);
  } catch {
    return undefined;
  }
}

// Label a directory with its diralias alias, falling back to the host's own
// abbreviated path when no alias matches.
async function resolveDirLabel(
  context: Context,
  directory: string,
): Promise<string> {
  const match = await resolveAliasMatch(directory);
  if (match !== undefined) {
    return formatAliasPath(match);
  }
  return context.ui.format.path(directory);
}

// Resolve the parts the path label draws: inside a repository the repository
// root and the directory's path within it, otherwise the directory's own label.
async function resolvePathDisplay(
  context: Context,
  directory: string,
): Promise<PathDisplay> {
  const repo = await resolveRepoLocation(directory);
  if (repo !== undefined) {
    return {
      inRepo: true,
      baseLabel: await resolveDirLabel(context, repo.root),
      suffix: repo.suffix,
    };
  }
  return {
    inRepo: false,
    baseLabel: await resolveDirLabel(context, directory),
    suffix: "",
  };
}

// The diralias widget: the directory label.
function DiraliasFooterStatus(props: {
  readonly sessionID?: string;
  readonly aliasTick: number;
}) {
  const context = usePlugin();
  const [display, setDisplay] = createSignal<PathDisplay | undefined>(undefined);

  // Location this footer labels: the session's own, or the app-wide one for the
  // home composer, which has no session.
  const location = () =>
    props.sessionID === undefined
      ? context.location ?? context.data.location.default()
      : context.data.session.get(props.sessionID)?.location;

  const directory = () => location()?.directory;

  // A repository directory takes the repository glyph in the theme's orange and
  // shows its root in the default foreground with the in-repo path in the muted
  // colour; elsewhere the folder glyph and a muted label are used.
  const glyph = (current: PathDisplay) =>
    current.inRepo ? REPO_GLYPH : FOLDER_GLYPH;
  const glyphColor = (current: PathDisplay) =>
    current.inRepo
      ? (context.theme.hue.orange?.[400] ?? "#ff8700")
      : context.theme.text.muted;
  const nameColor = (current: PathDisplay) =>
    current.inRepo ? context.theme.text.base : context.theme.text.muted;
  const suffix = (current: PathDisplay) =>
    current.inRepo && current.suffix !== "" ? `/${current.suffix}` : "";

  // Re-resolve the label whenever the directory changes or diralias bumps its
  // change-tick, so a rename of this directory's alias is picked up too.
  createEffect(
    on(
      () => [directory(), props.aliasTick] as const,
      ([dir]) => {
        if (dir === undefined) {
          setDisplay(undefined);
          return;
        }
        let active = true;
        void resolvePathDisplay(context, dir).then((resolved) => {
          if (active) {
            setDisplay(resolved);
          }
        });
        onCleanup(() => {
          active = false;
        });
      },
    ),
  );

  return (
    <Show when={display()}>
      {(current) => (
        <box flexDirection="row" flexShrink={1} minWidth={0}>
          <text
            fg={glyphColor(current())}
            selectable={false}
            wrapMode="none"
            truncate
            flexShrink={1}
            minWidth={0}
          >
            {`${glyph(current())} `}
          </text>
          <text
            fg={nameColor(current())}
            wrapMode="none"
            truncate
            flexShrink={1}
            minWidth={0}
          >
            {current().baseLabel}
          </text>
          <Show when={suffix(current()) !== ""}>
            <text
              fg={context.theme.text.muted}
              wrapMode="none"
              truncate
              flexShrink={1}
              minWidth={0}
            >
              {suffix(current())}
            </text>
          </Show>
        </box>
      )}
    </Show>
  );
}
