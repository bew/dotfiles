# stash-count plugin

Global OpenCode V2 TUI plugin: show how many prompts are in OpenCode's prompt stash.

## Behaviour

- The status line reads `Stash: 3`.
- It renders only while the current TUI has stashed prompts of its own.
  A stash made in another TUI is shared through the file but never enters this TUI's in-memory
  list, so it must not show here.
- It appears in the prompt footer and on the home screen.
- Hovering switches the text from bold yellow (theme yellow palette when defined, otherwise the
  terminal yellow) to white, and a left click opens the host stash list.
  The plugin does not render its own list.

## Data source

- Reads `prompt-stash.jsonl` from OpenCode's state directory:
  `$XDG_STATE_HOME/opencode/prompt-stash.jsonl`, defaulting to
  `~/.local/state/opencode/prompt-stash.jsonl`.
- Counts valid stash records, capped at the 50 entries OpenCode keeps.
- Watches the state directory, not the file, because pop and delete rewrite the file.
- A missing or unreadable file counts as an empty stash.
- Visibility does not come from the file: the plugin renders only while `context.keymap.commands()` contains the host's `prompt.stash.list` command.
  The host enables that command only while its own in-memory stash is non-empty, so it is the per-TUI truth, and a click always opens a non-empty list.
- The file is machine-global, so the number is the union across TUIs.
  With several TUIs stashing at the same time it can exceed this TUI's own list; there is no API that exposes that list's length.

## Notes

- There is no live stash API in the TUI plugin context, so the plugin reads the same file the host writes.
- Layout: discovered automatically from the global plugins root (`~/.config/opencode/plugins/`).
  `index.ts` is the server entry (no behavior); `tui.tsx` is the TUI entry.
