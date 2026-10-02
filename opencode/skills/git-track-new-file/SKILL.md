---
name: git-track-new-file
description: |
  Load whenever new files or directories are created in a git repo — via write, bash, or any
  other tool — so new files that should be tracked are registered with `git_track_new_file`.
metadata:
  maintainers: [bew]
---

Current working directory git status: !`git rev-parse --git-dir >/dev/null && echo "IS_GIT_REPO" || echo "NOT_GIT_REPO"`

If `NOT_GIT_REPO`: skip silently — do not call `git_track_new_file`.

Call `git_track_new_file` with the absolute path of each new file or directory that should be tracked, then continue.
Use judgment: skip paths that must not be tracked — e.g. `HANDOFF-*`/`TASK-*` artefacts — or where tracking is unwanted.

## Triggers

- `write` (new files) — including files written in this session
- `cp`, `cp -r`
- `mv` — destination path counts as new, even for renames
- `curl -o`, `wget -O`
- `mkdir` (if directory should be tracked, e.g. via `.gitkeep`)
- `tar`, `unzip` (use top-level output directory)

## Rules

- Absolute paths only.
- New files/directories only — not modified or existing ones.
- For renames: track all affected new paths, not just the ones pointed out.
- Non-blocking — never wait on the result.
