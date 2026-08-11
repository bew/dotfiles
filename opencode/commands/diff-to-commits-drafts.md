---
description: Split diff into commits, draft each message interactively (default: unstaged .)
subtask: false # shared context
---

Read `$ARGUMENTS` (may be empty). Extract if present:

- **Path**: a path or glob to narrow the diff (e.g. `src/`, `*.ts`). Default: `.`
- **Diff type**: `--staged` to use staged changes; `--unstaged` is default.

Resolve the diff source string:
- Staged + path: `git diff --staged -- <path>`
- Unstaged + path: `git diff -- <path>`

State these two resolved values clearly in context:
```text
Diff source: <resolved diff source string>
Working directory: <absolute path, from session prompt>
```

Then load the `diff-to-commits-drafts` skill and follow its instructions.
