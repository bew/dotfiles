---
name: git-intent-to-add
description: |
  Load when creating new files that should be tracked by git, so they appear in `git diff` and
  other git-aware tools immediately.
metadata:
  maintainers: [bew]
---

Current working directory git status: !`git rev-parse --git-dir >/dev/null && echo "IS_GIT_REPO" || echo "NOT_GIT_REPO"`

## Goal

After any tool call that creates new files that should be git-tracked, run `git add -N <file>`
on each new file to register intent-to-add before proceeding.

## Steps

1. Check the injected git status above.
   If `NOT_GIT_REPO`: skip all steps silently.
2. After each tool call that may have created new files:
   - `write` tool: created file is known — use it directly.
   - `bash` tool: infer created files from command
     (e.g. destination of `cp`, `mv`, output path of `curl -o`, …)
     If command created or copied a directory in repo (e.g. `mkdir`, `cp -r`, `tar`, `unzip`):
     use dir name instead of file for git command.
   - Other tools: skip.
3. For each inferred new file/dir:
   a. Check path against skip heuristic (see **Rules**).
   b. If not skipped: run `git add -N <file>` using `bash` tool.
4. Continue with task — do not block on this step.

## Rules

- Only run for new files (not git-tracked).
- Skip files that match any of these heuristic patterns:
  - Name starts with `.env` (e.g. `.env`, `.env.local`, `.env.production`)
  - Name ends with `.secret`, `.key`, `.pem`, `.p12`, `.pfx`
  - Path contains `node_modules/`, `__pycache__/`, `.cache/`, `dist/`, `build/`
  - Path is not in a git repo (e.g. under `/tmp/`)
  - Name ends with `.log`, `.tmp`, `.swp`
- Never run `git add` (full stage) — only `git add -N` (intent-to-add).
- Never abort current task if `git add -N` fails — note failure in chat response and continue.
