# cli-surface — exploration

## Findings

- Repo tooling convention: bash scripts in `bin/` with `.bats` tests (`git-new-files`, `git-without-new-files`, `opencode-artefacts-status`).
- Type detection by path convention: `_WIP_SPECS` → spec/exploration; `HANDOFF-*` → handoff.
- Per-item commit messages match the normal commit workflow (committer-style drafting).

## Design crux

Expose enough control (list, selective overlay, per-item sync, status/diff) without overfitting globs and modes before real usage.

## Candidate directions

- **Subcommand CLI** — `lab <cmd>`; verbs for bootstrap, listing, overlay, sync, and inspection. _(active)_

## Decisions

- **Subcommands**: `init`, `list [glob|--type t]`, `avail <path|glob|--all|--type t>`, `drop <path|glob|--all>`, `status`, `diff <path>`, `sync <item>`, `new <path>`, `rm <path>`. _(settled)_
- **On-demand + globs + `--type`** drives "how much to see". _(settled)_
- **`sync` is per-item and on-demand**, committing in the worktree with a proper drafted message. _(settled)_
- **`sync` adds in the worktree**, never on `main` — preserving the AGENTS.md `HANDOFF-*` rule. _(settled)_
- **`status`** reports branch-only / overlaid / dirty / missing. _(settled)_
- **`avail` of a path tracked on the current branch** should warn or refuse. _(settled as intent; exact behaviour open)_
- **Implementation**: bash `bin/<tool>` plus `.bats` tests. _(settled)_

## Open threads

- Final semantics of `new` (create an empty item and overlay it immediately?).
- Exact `--type` vocabulary and its path-convention mapping.