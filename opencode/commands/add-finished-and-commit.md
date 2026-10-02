---
description: Draft a commit for the task just finished, scoped to its files. Optional hint narrows the scope.
subtask: false # shared context!
---

FIRST: Load the `committer` skill and follow its instructions.

- Scope: infer from the session work items.
  If a commit occurred earlier in the session, treat it as the boundary —
  scope is the changes made since then.
- Diff type: unstaged

## User context

May be empty. If non-empty, treat as a focus hint for the scope / the files that belong to the just-finished task.

```
$ARGUMENTS
```
