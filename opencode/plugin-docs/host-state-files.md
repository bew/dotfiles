# Host state files

Some host data has no plugin API and no event.
OpenCode's prompt stash is one example: the TUI writes a local file, and plugins can only read that file.
This is the pattern for following such state without polling.

## When this applies

Use it when all of these hold:

- The plugin needs data the host already persists.
- No `context.data` event covers it.
- The host file is local to the same machine.

Otherwise prefer the plugin API.
A host file format is an internal contract and can change without notice.

## Shared file, per-client state

A file can be shared by several clients while each client keeps its own in-memory view, loaded
once at startup.
OpenCode's prompt stash is like that: the file is machine-global, but each TUI loads it once and
never re-reads it, so another TUI's later stash changes the file without entering this TUI's list.
Reading the file therefore reports the union across clients, not this client's state.

When the host exposes a command whose `enabled` tracks that per-client state, gate on
`context.keymap.commands()` instead of on the file.
`stash-count` renders only while `prompt.stash.list` is reachable, which is also the condition
that makes the click dispatch work.

## Resolving the state path

OpenCode resolves its state directory from `XDG_STATE_HOME`, defaulting to `~/.local/state`, then appends `opencode`.

```ts
import { homedir } from "node:os";
import { join } from "node:path";

const stateRoot =
  process.env.XDG_STATE_HOME ?? join(homedir(), ".local", "state");
const stateDir = join(stateRoot, "opencode");
```

Do not hard-code the file's absolute path; the directory moves with `XDG_STATE_HOME`.

## Reading defensively

- A missing or unreadable file means empty state, not an error.
  A fresh install has no file yet.
- Parse one line at a time and ignore malformed lines.
  One truncated write must not zero the whole count.
- Mirror the host's own cap when it has one.
  If the host keeps only the newest entries, extra lines in an oversized file are not real state.

## Watching the directory, not the file

Watch the parent directory and filter on the filename.

The host may replace the file wholesale on delete or rewrite.
That changes the inode, and a watcher attached to the old file stops receiving events.
A directory watcher keeps working across replacement.

```ts
import { watch } from "node:fs";

const watcher = watch(stateDir, (_event, filename) => {
  if (String(filename) === "target.jsonl") {
    scheduleRefresh();
  }
});
```

A single logical write can emit several file events.
Debounce the read with a short timer, and reset that timer on every event.
`stash-count` uses 50 ms.

Catch a missing state directory.
`watch()` throws when the directory does not exist yet, and the initial read still returns the correct empty state.
Either retry later or accept that a restart picks up the file.

## Lifecycle

Return a cleanup function from `setup` that:

- clears any pending refresh timer,
- closes the watcher,
- disposes the slot or other registrations that render the data.

Leaving a watcher open keeps the plugin alive past unload and can fire against a disposed reactive scope.

## Worked example

`../plugins/stash-count/` follows `prompt-stash.jsonl`:

- it resolves the state directory the way the host does,
- reads and validates JSONL records on setup,
- watches the directory and debounces refreshes,
- caps the count at the host's 50-entry limit,
- treats a missing file as an empty stash,
- gates rendering on the host's own stash command instead of the shared file.
