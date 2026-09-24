# overlay-model — exploration

## Findings

- The design branch tree mirrors repo-relative paths, so an item's branch path equals its working-tree path.
- Items may be files (handoffs) or directories (specs/exploration dirs holding several files).
- A manifest is needed to know which items are currently overlaid.
- Per-worktree state is available via `git rev-parse --git-path <name>`: the main worktree resolves to `.git/<name>`, a linked worktree to `.git/worktrees/<n>/<name>`.

## Design crux

How to project items from the hidden branch into the working tree as untracked files, track which are projected, and push edits back — with an unambiguous source of truth per edit.

## Candidate directions

- **D3 — copy + manifest** — copy an item from the worktree into the tree at the same relative path; record the path in a per-worktree manifest; `sync` copies the item back into the worktree and commits. _(active)_
- **D4 — symlink overlay** — drop a symlink into the tree pointing at the worktree; edits are live; `sync` just commits. _(rejected — contradicts the "untracked copy" model; symlinks could be committed)_
- **D5 — derive, no manifest** — available set = any untracked file whose path exists on the branch. _(rejected — fuzzy; cannot distinguish incidental files)_

## Decisions

- **Copy + manifest (D3)** — `avail <item>` copies worktree → tree (untracked) and records the path; `drop` removes the copy and the manifest entry (branch untouched); `sync <item>` copies tree → worktree and commits. _(settled)_
- **Manifest is per-worktree** — newline-separated repo-relative paths, stored at `git rev-parse --git-path <tool>-manifest`. _(settled)_
- **Items are file-or-dir paths**; directory items are copied recursively. _(settled)_
- **The overlay copy is authoritative on sync** — if the worktree copy was independently modified, `sync` warns before overwriting. _(settled)_

## Open threads

- Behaviour when `avail` targets a path still tracked on `main` (warn or refuse).
- Whether `sync` also commits unrelated dirty files already present in the worktree, or only the named item.