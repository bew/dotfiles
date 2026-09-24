# storage-backend — exploration

## Findings

- A single worktree can only have one branch checked out at a time; the design branch therefore needs its own checkout, or plumbing that avoids one.
- `git worktree add --orphan -b <branch> <path>` is supported on git 2.54.
- git does not reject a worktree nested inside another worktree; it only rejects a worktree inside `$GIT_DIR`.
- An orphan branch shares no ancestor with `main`, so it can never be accidentally merged or rebased into it.
- Worktree registration lives in `.git/worktrees/<name>/` (machine-local, not cloned).

## Design crux

Where the branch physically lives determines the overlay mechanics, the bootstrap steps, and whether a second on-disk checkout exists to keep in sync.

## Candidate directions

- **D1 — in-repo orphan worktree** — `git worktree add --orphan -b specs-and-design .lab`; the branch tree mirrors repo-relative paths; overlay is a same-path copy. _(active)_
- **D2 — plumbing, no checkout** — keep the branch as a ref in the object DB; materialise via `git show <branch>:<path>`; commit via a temp index (`GIT_INDEX_FILE` + `read-tree` + `update-index` + `write-tree` + `commit-tree` + `update-ref`). _(deferred)_

## Decisions

- **Use D1 now** — orphan branch `specs-and-design`, checked out as an in-repo worktree whose dir tracks the final tool name (`.lab` placeholder), self-bootstrapped by `lab init`. _(settled)_
- **Document D2 in the spec as future work** — pursue only if the second checkout causes practical friction. _(settled)_
- **The branch is orphan** — independent history, cannot be merged into `main`. _(settled)_

## Open threads

- Confirm the exact `git worktree add --orphan` invocation and first-commit bootstrap on git 2.54.