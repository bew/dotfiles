# `Phase:Rewire` — fix both repos

In `$dest`:
- Fix broken relative refs and docs links that pointed outside the part.
- Replace old source-repo URLs with the new repo URL.

In `$srcroot` (only if removal was confirmed in `Phase:Decide`):
- Remove the part: `git -C "$srcroot" rm -r -- "$parts"`.
- Update consumers to the chosen ref (flake input, import path, package dependency).
- **Lockfile caveat**: switching a consumer to a remote URL invalidates its lockfile.
  It cannot be re-locked until the new repo is pushed.
  Note this as a pending user action.
  A local `path:` ref avoids the caveat until then.

Summarize: new repo path/branch/commits, remote, source changes, and pending user actions.
Never push.
