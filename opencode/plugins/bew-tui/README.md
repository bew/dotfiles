# bew-tui plugin

Global OpenCode V2 TUI plugin: a bundle of widgets that adjust the OpenCode TUI.
Each component is self-contained and unit-testable on its own.

## Components

### diralias footer

Shows the current directory's [diralias](https://github.com/bew/diralias) alias
in the prompt footer, so a deep directory reads as `~alias` instead of the full
abbreviated path.

It contributes to the host's `prompt.footer.status` slot — the prompt footer's
left region, which normally holds the location label and, while a session runs,
the running spinner. `tui.tsx` replaces that slot and composes this component
with the branch label in one row.
The shared prompt composer renders that slot both in a session and on the home
screen, so the home composer is covered by the same claim.
The plugin takes the whole region over and draws the running scanner while a
session runs, and the directory label, which stays visible.

Outside a repository the label is the directory's alias (`~alias`, or
`~alias/remainder` for a directory under an alias when one matches), or the
host's abbreviated path otherwise, prefixed with a folder glyph — e.g.
`󰙅 ~dotfiles`.

Inside a git repository the label splits at the repository root: the repository
glyph replaces the folder glyph and shows in the theme's orange, the root name
shows in the default foreground, and the path within the repository follows in
the muted colour — e.g.
` ~dotfiles/opencode`.
The root and the path within it come from `git rev-parse --show-toplevel
--show-prefix`, and the root is labelled with `diralias get <root>`, falling
back to the host's abbreviated path.
Inside a repository the alias therefore applies to the repository root, so an
alias pointing below the root is not used there.

Alias lookups run `diralias get`.
That is authoritative — it applies diralias's own prefix and most-specific-target
rules — and the one-off process cost is paid only when the directory or the
alias set changes.

This needs `diralias` on `PATH`.
A missing binary and a directory with no matching alias both fall back to the
host's abbreviated path.

The plugin watches `$XDG_STATE_HOME/diralias` and re-resolves on every
`change-tick`, which diralias bumps on every alias change.
Re-resolving on the tick (not only on a directory change) is what picks up a
rename of the alias for the current directory.

Trade-offs:

- The worktree-move progress and `(new worktree)` text are host-internal and
  cannot be reproduced, so they are lost while the plugin owns the slot.
- The `esc` interrupt hint is not shown.
- The label is not clickable; the host's menu (copy path / open folder /
  workspaces) is not reachable from a plugin.

### git-branch label

Shows the git branch of the current directory beside the path label, each part
coloured on its own: the branch glyph takes the repository glyph orange, the
branch name stays in the default foreground but turns warning-coloured when the
working tree is dirty, the ahead count shows in a dark orange and the behind
count in error.

The label is the branch glyph, the branch name, and, when the branch diverges
from its upstream, the ahead/behind counts — e.g. ` main ↑1 ↓2`.
The branch name comes from the host's VCS data (reactive, no spawn).
The working-tree status comes from `git status --porcelain=v2 --branch`, run in
the labelled directory: the host's `VcsInfo` carries no working-tree state, so
the status must be recomputed from a spawn.

The status re-runs when the directory changes, when the branch changes, and on
an adaptive poll: every 3 s while a session in the directory runs or any TUI
event arrived in the last 15 s, otherwise doubling the interval on each
unchanged run up to 3 min.
A run that passes one second shows a small braille loader beside the label until
the status lands.

Trade-offs:

- The status is recomputed by a spawn rather than pushed by the host, so it can
  lag a change by up to the current poll interval.
- The host publishes no working-tree event, so polling is timed, not
  event-driven: a change is picked up on the next run, not immediately.
- `git status` reports the whole repository, not only the labelled directory, so
  the dirty colour follows a change anywhere in it.

### running spinner

The running indicator the footer draws: a port of the host's knight-rider
scanner (`knight-rider-scanner.ts`, pure and unit-tested) rendered through the
host's globally registered `<spinner>` element (`running-spinner.tsx`).
Its color maths lives in `lib/colors.ts`, shared with any future component that
needs a trail ramp or a dimmed variant of a theme color.

## Layout

This is a directory plugin, discovered automatically from the global plugins
root (`~/.config/opencode/plugins/`).
No config entry is needed.

- `index.ts` — server entry (a no-op).
- `tui.tsx` — TUI entry; composes the components and claims the host slot they
  render into.
- `components/` — the widgets. A component that spans several files keeps its
  own folder (`components/<name>/`); a single-file component sits directly under
  `components/`.
- A component that renders into a slot exposes a `create*()` factory returning
  `{ render, dispose }`; `tui.tsx` calls the factory, composes the renders,
  claims the slot, and aggregates the disposers.
- `components/spinner/` claims no slot and exposes no factory; it holds the
  shared leaf primitives the footer components draw — the running scanner and
  the braille loader.
- `lib/` holds unit-tested building blocks free of host and Solid types: the
  color primitives, the git-status and git-repo parsing, and the adaptive git
  poller.

Run the component tests with `just test bew-tui` from the `opencode` directory.

## OpenTUI

Components draw through OpenTUI: the host's `<spinner>` element and its `RGBA`
color type.
`@opentui/core` is therefore a dependency of the config package, which is what
lets those types resolve in the editor and the color modules load under
`bun test`.

Keep it in sync with the OpenTUI version OpenCode bundles — the `@opentui/core`
entry in the catalog of OpenCode's root `package.json`.
A mismatched copy loads as a second `@opentui/core` instance next to the host's
own, and the colors it builds cross into the host renderer.

Footer glyphs and status counts set `selectable={false}`, so they stay
decoration; the directory path and the branch name stay selectable, so a mouse
drag copies them without the glyphs.
