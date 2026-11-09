# git-branch label

## Purpose
The footer widget that shows the current directory's git branch, with ahead and behind markers and a dirty colouring; the label reads ` main ↑1 ↓2`.
`tui.tsx` composes it into the host's `prompt.footer.status` slot, after the running indicator and the directory label; the widget claims no slot itself.

## Responsibilities
- The branch name, read from the host's VCS data rather than spawned.
- The working-tree state — dirty, ahead, behind — from the widget's own `git status` call.
- Cadence: re-read when the directory or the branch changes, otherwise on an adaptive poll.

## Architecture
The branch name comes from the host's VCS info for the current location, which is reactive and costs no process.
Everything else comes from `git status --porcelain=v2 --branch`, spawned in the labelled directory, so the markers follow the whole repository rather than one subdirectory of it.

The poll that drives those spawns adapts: it runs every few seconds while the directory is active and backs off towards minutes while nothing changes.
Activity arrives as the host's event stream, and a running session whose directory matches holds the poll at its floor so a live change is reflected promptly.
A status call that outlives a moment shows a braille loader beside the label.

## Failure behaviour
- A failed or timed-out `git status`, an absent git binary, and a directory outside any repository all leave the branch visible without its markers.

## Conventions
- A directory with no branch still reports a resolved status, so the poller backs off instead of polling it forever.
- The poller belongs to the factory, so `dispose` stops it along with its activity subscription.
- A status report for a directory that is no longer current is ignored.

## Trade-offs
- The status is spawned rather than pushed by the host, so it can lag a change by up to the current poll interval.
- `git status` reports the whole repository, so the dirty colour follows a change anywhere in it.
