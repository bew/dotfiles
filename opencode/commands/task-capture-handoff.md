---
description: Capture one explicitly-named task from this session as a TASK-* note. Pass the task (and optionally its target project) as context.
subtask: false # shared context!
---

Load the `work-capture-handoff` skill in mode `capture-task`, and follow its instructions.

## User context

May be empty. If non-empty, treat as input to the skill's Setup step —
the task to capture and, optionally, its target project directory.

```
$ARGUMENTS
```
