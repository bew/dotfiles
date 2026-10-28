---
description: Status report on findings and in-flight work, then resume (optional focus hint)
subtask: false # shared context!
---

Report status from existing context only. No new tool calls, no subagents.

Format:
**Goal** — what this turn is trying to achieve.
**Findings** — what is established, with paths, commands, errors. No history recap. Skip if none.
**Right now** — the step or option being explored, and whether a tool call was cut off.
**Next step** — what would have happened next.

Keep the report under 15 lines.
Then resume from **Next step** without waiting.
If the report makes the work moot, say so in one line and stop.

Exception: on `agent-blocker` or `agent-stuck` conditions,
replace **Right now** and **Next step** with **Blocked**.
State the blocker, the raw error, and what is needed from the user.
Then stop. Do not resume.

## Focus hint

May be empty. If non-empty, weight the report toward it.
```
$ARGUMENTS
```
