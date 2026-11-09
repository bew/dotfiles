# diralias footer

## Purpose
The prompt-footer widget that labels the current directory as its diralias alias.
A label reads `󰙅 ~dotfiles` outside a repository and ` ~dotfiles/opencode` inside one, with the part within the repository muted.
`tui.tsx` composes it into the host's `prompt.footer.status` slot, beside the running indicator and the branch label; the widget claims no slot itself.
When diralias knows no alias for the directory, the label falls back to the host's abbreviated path.

## Responsibilities
- Alias resolution: ask diralias for the directory's alias and show it in its `~alias` form.
- Repository split: label the repository root and append the path within it, so a deep working directory still reads short.
- Freshness: re-resolve when the session's directory changes, or when diralias reports that its alias set changed.

## Architecture
The directory comes from the session's location, or from the app-wide default on the home composer.
`resolvePathDisplay` runs `git rev-parse --show-toplevel --show-prefix` in that directory: inside a repository the label is the repository root plus the in-repo suffix, otherwise the directory itself.
`resolveDirLabel` then asks diralias for an alias through `diralias get`, and falls back to the host's path formatter when there is no match.
Both spawns are abandoned after a timeout, so a hung binary cannot stall the footer.

The widget watches diralias's state directory for its change marker and re-resolves after a short debounce.
That watch belongs to the factory, not to the rendered component, so it survives a slot re-render; its disposer closes the watcher and clears the pending timer.
Resolve the state directory from `XDG_STATE_HOME`, the way diralias does, never from a fixed path.
The alias and path parsing sits in `alias-label.ts`, free of host and OpenTUI types so it stays unit-testable.

## Failure behaviour
- A missing or failing diralias binary, and a directory with no matching alias, both fall back to the host's abbreviated path.
- A failed `git rev-parse`, including a directory outside any repository, yields a plain directory label.

## Trade-offs
- The host's worktree-move progress text and its `(new worktree)` marker are host-internal, so they are lost while this widget owns the slot.
- The `esc` interrupt hint is not shown.
- The label is not clickable, so the host's menu — copy path, open folder, workspaces — is unreachable from a plugin.
