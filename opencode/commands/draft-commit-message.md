---
description: Draft a git commit message from diff (defaults to staged changes)
subtask: false # shared context!
# note: diff never pollutes the shared context, diff explorer agent handles it
---

Draft a commit message for a diff (defaults to staged changes; args may override).

## Arguments

Read `$ARGUMENTS` (may be empty). Extract if present:

- **Scope**: a path, glob, or area that should narrow the diff (e.g. `src/adapters/`, `*.ts`).
- **Focus**: a free-text note to guide writing the commit message.
  If it looks like a diff scope — use it as such.
  If it looks like intent or emphasis — pass it as focus context.
  Both may be present.

If no arguments were provided: proceed with defaults — full staged diff, no extra context.

## Action

Load the `draft-commit-message` skill and follow its steps, passing any parsed scope and focus.
