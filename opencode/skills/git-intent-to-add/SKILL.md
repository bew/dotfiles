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

After bash commands that create new files in the repository, call the `git_intent_to_add` tool
to register those files with git before proceeding.

The `git_intent_to_add` tool is provided by the `git-intent-to-add` plugin (auto-loaded globally).
It handles all skip heuristics, realpath resolution, and retry logic internally.

## When to call

After any `bash` tool call that creates new files or directories in the repository — for example:

- `cp`, `cp -r`
- `mv` (for new destination paths)
- `curl -o`, `wget -O`
- `mkdir` (if the directory itself should be tracked, e.g. via a `.gitkeep`)
- `tar`, `unzip` (use the top-level output directory)

## When NOT to call

- After `write` tool calls — the plugin handles those automatically.
- For files under `/tmp/` or outside the repository.
- When in `NOT_GIT_REPO` (check injected status above).

## Steps

1. Check the injected git status above.
   If `NOT_GIT_REPO`: skip silently.
2. After a `bash` tool call that created new files:
   call `git_intent_to_add` with the absolute path of each new file or directory.
3. Continue with task — do not block on this step.
