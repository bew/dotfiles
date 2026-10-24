---
description: Capture one explicitly-named bug from this session as a BUG-* note, with optional target project.
subtask: false # shared context!
---

Load the `work-capture-handoff` skill in mode `capture-bug`, and follow its instructions.

## User context

May be empty. If non-empty, treat as input to the skill's Setup step —
the bug to capture and, optionally, its target project directory.
Say "confirmed" or "reproduced" there to file the bug with a `[CONFIRMED]` H1 tag.

```
$ARGUMENTS
```
