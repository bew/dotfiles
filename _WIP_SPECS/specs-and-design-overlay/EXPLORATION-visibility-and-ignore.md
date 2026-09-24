# visibility-and-ignore — exploration

## Findings

- "Untracked" alone does not prevent accidental commits: `git add -A` or `git commit -a` would stage untracked files onto the working branch.
- The in-repo worktree dir (`.lab/`) contains a `.git` file; if not ignored, `git add -A` treats `.lab/` as an embedded repository and stages a gitlink (mode 160000) instead of its contents.
- `.git/info/exclude` lives in the common git dir and is shared across worktrees; `.gitignore` is committed and clone-wide.

## Design crux

How strongly to enforce "never committed on the working branch" versus the simplicity of shipping with no ignore rules.

## Candidate directions

- **D6 — no ignore for now** — rely on the user not running `git add -A`. _(active)_
- **D7 — managed `.git/info/exclude`** — the tool owns a marked block with per-path entries; never committed. _(deferred)_
- **D8 — global `.gitignore` patterns** — `_WIP_SPECS/`, `HANDOFF-*`, `EXPLORATION-*`, `SPEC*.md`. _(rejected — blunt; commits the rule to `main`)_
- **Ignore `.lab/` only** — a single entry so the worktree dir never pollutes status nor gets gitlink-staged. _(deferred, high priority)_

## Decisions

- **No artefact ignore for now (D6).** _(settled)_
- **Ignoring `.lab/` is deferred but high priority** — its absence risks gitlink staging on `git add -A`. _(settled)_
- **When it is eventually added, prefer `.git/info/exclude`** over a committed `.gitignore`. _(settled)_

## Open threads

- Decide the `.lab/` ignore location when it gets implemented.