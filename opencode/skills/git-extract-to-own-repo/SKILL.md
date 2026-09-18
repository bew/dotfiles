---
name: git-extract-to-own-repo
description: |
  Extract part of a git repo (a directory or subsystem) into a standalone repo, preserving
  chosen history via git-filter-repo, then rewire consumers and remove the part from the source.
  Load when user asks to "extract X into its own repo", "split out a subproject",
  "move part of this repo to a new repo", "make X a standalone repo",
  "pull X out of the monorepo", or similar extraction/split requests.
metadata:
  maintainers: [bew]
---

# Git extract to own repo

## Goal

Move chosen path(s) out of a source repo into a new standalone repo, preserving selected history,
then fix references in both repos.

## Setup — resolve inputs

Determine the following from context (user message, prior context, defaults):

- **Source repo**: repo to extract from. Default: `git rev-parse --show-toplevel` of cwd.
- **Part path(s)**: one or more paths relative to the source toplevel.
  Required — stop and ask if absent.
- **Target repo path**: where the new repo is created. Default: sibling `../<name>`,
  with `<name>` derived from the part's directory name.
- **Remote URL**: new repo's `origin` (e.g. `git@github.com:<user>/<name>.git`). Default: `(none)`.
- **Push policy**: `never` unless the user explicitly says to push.
- **Hints**: free-form remainder. Default: `(none)`.

State resolved values:
```text
Source repo: <path>
Part path(s): <list>
Target repo: <path>
Remote URL: <url or "(none)">
Push policy: never
Hints: <hints or "(none)">
```

Prerequisites — check before any phase:
- `command -v git-filter-repo` — if absent: stop.
  Tell the user to install it.
  Do not auto-install.
- Extraction always works on a clone.
  The source working tree may be dirty; record that state but do not clean it.

**Vars used throughout**: (output them in context once known)
- `$srcroot` — source repo toplevel.
- `$parts` — confirmed part path(s) relative to `$srcroot`.
- `$dest` — new repo path.
- `$remote` — new repo's remote URL, or `(none)`.
- `$branches` — selected branch(es) to extract; one or more.
  Resolved in `Phase:Decide`, not defaulted.

## Phases

1. `Phase:Recon` — inspect repo state, part files, history depth, consumers
2. `Phase:Decide` — user gate on what moves, branch(es), history depth, target/remote,
   source cleanup
3. `Phase:Extract` — clone, filter history, set branch + remote, verify
4. `Phase:Rewire` — fix refs in the new repo; update and prune the source repo

## 1. `Phase:Recon` — inspect before deciding

Run `bash "<skill-dir>/scripts/recon" "$srcroot" "${parts[@]}"` and read its report.
If the script cannot run, or its all-branch history output needs interpretation,
read <./refs/history-exploration.md> for the fallback commands and history depths.

Also inspect:
- **Worktree/submodule**: `cat "$srcroot/.git"` (a gitfile means worktree or submodule);
  `git -C "$srcroot" rev-parse --git-dir --git-common-dir`.
- **Consumers**: the bundled script already reports consumer and lockfile hits.
  Fallback commands live in <./refs/history-exploration.md>.
- **Docs refs**: relative links pointing into or out of the part break after extraction.

Report to the user: files to move, history depth counts, renames/prior locations, consumer hits.
Collect the *unsure* points for `Phase:Decide`.

Ready to move to `Phase:Decide`? (say 'next' or similar to proceed)

## 2. `Phase:Decide` — confirm the unsure points

Use the `question` tool.
Cover every point, then state the final choices:

- **Exact paths to move** — confirm against the Recon file list, including coupled sub-modules.
- **Branch(es) to extract** — one or more, user choice.
  Ask when Recon's all-branch commit count exceeds the current-branch count,
  or prior locations appear on other branches.
  Otherwise default to the current branch.
- **History depth** — the three depths in <./refs/history-exploration.md>, with counts from Recon.
  Fresh single commit is the alternative.
- **Target repo path** and whether to set a **remote URL**.
- **Consumer ref scheme** — local `path:../<name>` vs remote `github:<user>/<name>` etc.
- **Remove part from source now?** — removal needs explicit confirmation.
- **Push policy** — default `never`; only push if the user explicitly asks.
- **Commit policy** in the new repo — commit fixes, or leave uncommitted.

State resolved values and update the `Vars` block.

Ready to move to `Phase:Extract`? (say 'next' or similar to proceed)

## 3. `Phase:Extract` — clone, filter history, set branch + remote, verify

When entering `Phase:Extract`: read <./refs/phases/extract.md> for full instructions.

## 4. `Phase:Rewire` — fix refs in the new repo; update and prune the source repo

When entering `Phase:Rewire`: read <./refs/phases/rewire.md> for full instructions.

## Rules

- NEVER rewrite the source repo's history.
  Clone first; filter only the clone.
- NEVER push unless the user explicitly asks.
- Removing the part from the source requires explicit user confirmation.
- If `git-filter-repo` is missing: stop and tell the user.
  Do not auto-install.
