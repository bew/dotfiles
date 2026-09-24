# Specs & Design Overlay — exploration brief

## Motivation

Context: design artefacts — specs, explorations, handoffs, TODO/FIXME notes — live scattered across this repo.
Some are tracked on `main` (e.g. `_WIP_SPECS/do-it-later-task-manager/SPEC.md`, `nix/_WIP_SPECS/wrapkit-system/*`, `nvim/_WIP_SPECS/*`, `opencode/_WIP_SPECS/*`), and some sit untracked as `??` noise (e.g. `desktop/os-darwin/hammerspoon/_WIP_SPECS/`, `nvim/TODO_*`, `opencode/skills/coder-nix/HANDOFF-*.md`).

Problem: there is no way to version these artefacts without polluting `main` and feature branches, and no way to surface a chosen subset into the current worktree without committing it there.
`HANDOFF-*` must never be committed to a working branch (repo `AGENTS.md` rule).

Goal: version all such artefacts on a dedicated branch (`specs-and-design`), and let the user project selected items into the current worktree as untracked files, on demand.

Scope: a CLI (placeholder name `lab`) that manages a dedicated orphan branch, an in-repo git worktree for it, and an overlay of selected items into the working tree.

Out of scope (for now):
- Ignoring the overlay artefacts.
- Migrating the artefacts already tracked on `main`.
- The plumbing-based storage backend (documented in the spec as future work).
- Multi-user / collaborative use.

## Topics

- (frozen) `storage-backend` — where the `specs-and-design` branch physically lives.
- (frozen) `overlay-model` — how items are projected into the working tree and synchronised back.
- (frozen) `visibility-and-ignore` — how artefact untracked/ignored status is enforced.
- (frozen) `cli-surface` — the tool's subcommands and their semantics.
- (active) `naming` — exact tool name and derived paths.