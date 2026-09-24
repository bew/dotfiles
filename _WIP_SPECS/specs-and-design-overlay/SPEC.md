# [DRAFT] Specs & Design Overlay

> IMPORTANT: Before any drafting/planning/editing of this spec,
> agents MUST load one of the spec-writing skill first.

## Introduction

This repo accumulates design artefacts — specs, explorations, handoff docs, TODO/FIXME notes — scattered across the tree.
Some are committed to `main` (e.g. `_WIP_SPECS/do-it-later-task-manager/`, `nix/_WIP_SPECS/wrapkit-system/`), and some sit as untracked `??` noise (e.g. `desktop/os-darwin/hammerspoon/_WIP_SPECS/`, `nvim/TODO_*`, `opencode/skills/coder-nix/HANDOFF-*.md`).
There is no way to version these without polluting the working branch, and no way to surface a chosen subset into the current worktree without committing it there.
`HANDOFF-*` must never be committed to a working branch (repo `AGENTS.md` rule).

The goal is a CLI (placeholder name `lab`) that versions all such artefacts on a dedicated branch (`specs-and-design`) and projects selected items into the current worktree as untracked files, on demand.

Out of scope for now: ignoring the overlay artefacts, migrating artefacts already tracked on `main`, and the plumbing-based storage backend (documented as future work).

Detail: [EXPLORATION-BRIEF.md](./EXPLORATION-BRIEF.md).

## Naming & IDs

- Design name: **Specs & Design Overlay**.
- Git branch: `specs-and-design` (fixed; orphan).
- Tool name: `<tool>` — placeholder `lab` (open).
- Worktree dir: `.<tool>` (e.g. `.lab`).
- Manifest: `git rev-parse --git-path <tool>-manifest` (per-worktree).
- Item path: a repo-relative path; the branch tree mirrors it exactly.

Detail: [EXPLORATION-naming.md](./EXPLORATION-naming.md).

## Interface / How to use

CLI: `<tool> <cmd>`.

- `init` — create the orphan branch + in-repo worktree, seed the manifest.
- `list [glob|--type t]` — list items on the branch.
- `avail <path|glob|--all|--type t>` — copy item(s) from the worktree into the current tree (untracked); record in the manifest.
- `drop <path|glob|--all>` — remove overlay copies + manifest entries (branch untouched).
- `status` — report branch-only / overlaid / dirty / missing.
- `diff <path>` — diff the overlay copy against the branch.
- `sync <item>` — copy the overlay back into the worktree and commit it there with a drafted message.
- `new <path>` — start a new item (overlay, untracked).
- `rm <path>` — delete an item from the branch (and overlay).

Detail: [EXPLORATION-cli-surface.md](./EXPLORATION-cli-surface.md).

### Open Questions

- Exact `--type` vocabulary and its path-convention mapping. Non-blocking. Only `spec`/`exploration`/`handoff` are implied so far.
- Final `new` semantics (create empty item and overlay immediately?). Non-blocking. Affects UX only.

## Storage Model

The branch is `specs-and-design`, checked out as an **in-repo orphan worktree** at `.<tool>`.
Orphan history makes it unmergeable into `main`.
The branch tree mirrors repo-relative paths, so an item's branch path equals its worktree path.
`init` bootstraps the worktree and manifest.

Detail: [EXPLORATION-storage-backend.md](./EXPLORATION-storage-backend.md).

### Open Questions

- Confirm the exact `git worktree add --orphan` invocation and first-commit bootstrap on git 2.54. Non-blocking. Verified feasible; only the exact command shape remains.

## Overlay Model

`avail <item>` copies the item from the worktree into the current tree at the same relative path (untracked) and records the path in the per-worktree manifest.
`drop` removes the copy and the manifest entry; the branch is untouched.
Items are files or directories (copied recursively).
The overlay copy is authoritative on sync; if the worktree copy was independently modified, `sync` warns before overwriting.

Detail: [EXPLORATION-overlay-model.md](./EXPLORATION-overlay-model.md).

### Open Questions

- Behaviour when `avail` targets a path still tracked on `main`. Non-blocking. Warn or refuse — exact behaviour to settle.
- Whether `sync` also commits unrelated dirty files already in the worktree, or only the named item. Non-blocking. Affects predictability.

## Sync Model

`sync <item>` copies the overlay copy back into the worktree and commits it there with a proper, drafted message.
Commits happen in the worktree, never on `main` — preserving the `AGENTS.md` `HANDOFF-*` rule.
Sync is per-item and on-demand.

Detail: [EXPLORATION-cli-surface.md](./EXPLORATION-cli-surface.md), [EXPLORATION-overlay-model.md](./EXPLORATION-overlay-model.md).

## Visibility & Ignore

No artefact ignore for now; the user avoids `git add -A`.
Ignoring the `.<tool>/` worktree dir is deferred but high priority: without it, `git add -A` stages `.<tool>/` as an embedded-repo gitlink (mode 160000).
When added, prefer `.git/info/exclude` over a committed `.gitignore`.

Detail: [EXPLORATION-visibility-and-ignore.md](./EXPLORATION-visibility-and-ignore.md).

### Open Questions

- When the `.<tool>/` ignore entry lands and where. Non-blocking now, but becomes blocking the moment `git add -A` is used.

## Placement / Scope

Items may live anywhere in the repo; the branch mirrors repo-relative paths, including nested dirs (e.g. `nvim/_WIP_SPECS/...`).
Types are inferred by path convention: `_WIP_SPECS` → spec/exploration; `HANDOFF-*` → handoff.

Detail: [EXPLORATION-overlay-model.md](./EXPLORATION-overlay-model.md).

## Design Options

**D1 — in-repo orphan worktree** (chosen): second checkout at `.<tool>/`; overlay is a same-path copy; free `git log/diff/ls-tree`. Needs a dir and can go stale.
**D2 — plumbing, no checkout** (future): branch as a ref only; materialise via `git show <branch>:<path>`; commit via a temp index (`read-tree`/`update-index`/`write-tree`/`commit-tree`/`update-ref`). Single worktree, more code, `git show` ergonomics only.

Decision criteria: use D1 unless the second checkout causes practical friction; switch to D2 only if that friction is real.

Detail: [EXPLORATION-storage-backend.md](./EXPLORATION-storage-backend.md).

## Alternatives & Tradeoffs

- **Symlink overlay** — live edits, no copy-back; but symlinks can be committed and contradict the untracked-copy model. Rejected.
- **Plumbing-only** — single worktree, no second checkout; but custom code and weaker git ergonomics. Deferred (D2).
- **No tool / manual** — simplest; but no versioning of hidden artefacts and no on-demand surfacing. Fails the goal.
- **Global `.gitignore` patterns** — simple; but blunt and commits the rule to `main`. Rejected in favour of no-ignore-now / managed exclude later.

## Related Artifacts

- Exploration material lives beside this spec: `EXPLORATION-BRIEF.md` and `EXPLORATION-*.md` in this directory.
- Repo tooling convention: bash scripts in `bin/` with `.bats` tests (`git-new-files`, `git-without-new-files`, `opencode-artefacts-status`).
- Existing artefact convention this design must coexist with: `_WIP_SPECS/` dirs (some tracked on `main`) and `HANDOFF-*` files (never tracked).

## Global Open Questions

**Terminology & Key Concepts** (TKC) — Whether this section is needed for this spec.
Non-blocking. Refer to spec-writing skill for guidance.

**Exact tool name** — `lab` (placeholder) vs `atelier` vs `sketch`.
Non-blocking. `lab` works everywhere as a placeholder; the name only affects the binary and derived paths.