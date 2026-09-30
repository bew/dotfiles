---
name: task-capture-handoff
description: |
  Captures one deferred, explicitly-named task from the current session as a small
  TASK-* note — an intent to do later, for a future user or agent to pick up.
  Load when the user defers a task unrelated to the current work, e.g.
  - deferral/reminder, like "defer/remember for later"
  - off-topic marker, like "unrelated, but …"
  - deferred intent, like "we'll come back to this"
  - explicit, like "LATER: …" or "TASK(<when>): …"
metadata:
  maintainers: [bew]
---

IMPORTANT: Do not invoke `compress` while producing this task capture.
If a context compression is due, write the doc first, then compress.
Keep compression blocked even when the PLAN-mode guard halts the write —
release it only once the doc has actually been written.

## Setup — resolve inputs

Determine these from whatever is available in context
(user message, prior context, or defaults):

- **Task**: what the capture is about. Required — never inferred.
  If absent, stop and ask the user.
- **Output dir** (`$dir`): the target project directory for the task.
  Derive from the task's subject.
  If the task does not map to a project/repo, ask the user.
  Never default to cwd.

State resolved values:

```text
Task: <value>
$dir: <resolved path>
```

**Vars used throughout**: (output them in context once known!)
- `$dir` — resolved output directory.
- `$date` — capture timestamp.
- `$existing` — existing `TASK-*` files in `$dir`.
- `$slug` — kebab-case label derived from the task.
- `$filename` — `TASK-$date-$slug.md`

## Step 1 — Scan

Compute vars:
- `$date` — run `date +%Y%m%dT%H%M`.
- `$existing` — list existing `TASK-*` files in `$dir`.
- `$slug` — derive from the task. Kebab-case, max ~10 words.
  Never use `task`, `session`, or `handoff` alone as the slug.
- `$filename` — `TASK-$date-$slug.md`

Scan the session for material pertaining to the task only:

1. **Provenance**: what in the session triggered this task.
2. **Task-relevant decisions** and open sub-questions.
3. **Task-relevant artefacts**: paths or URLs touched or needed to do it.
4. **The task's own blockers or prerequisites** — anything that must happen first.

Drop everything else.
Do not carry blockers or prerequisites that belong to other unrelated threads.

## Step 2 — Write

NOTE: If the session is in PLAN mode: stop immediately.
Output: "Cannot write the capture in PLAN mode — switch to BUILD mode first, then re-run."
Do not proceed until the user has switched modes and re-requested.

If `$filename` is in `$existing`: adapt the filename (e.g. append a numeric suffix)
so nothing is overwritten.

Read <./refs/template.md> for the required doc structure.
Write the capture to `$dir/$filename` with the `write` tool, without asking for confirmation.

If the write fails (e.g. `$dir` does not exist): tell the user and ask how to proceed.

After writing, tell the user:

> Task capture written to `<full path>` — open to inspect.

NEVER output the doc content inline.

## Rules

- ALWAYS write the capture with the `write` tool.
  Never output the doc content inline in the conversation.
- Do not inline file contents — reference by path only.
- ONLY include content relevant for the task.
- ONLY reference URLs that were confirmed valid in the session.
- Run commands to get missing information (date, existing `TASK-*` list) in one tool call, not
  multiple.
- NEVER include meta-commentary about the capture doc itself
  (e.g. "no other files were referenced", "this section does not apply").
  State content, not commentary about the doc.
- NEVER reference the skill or template that produced this capture
  (e.g. the `task-capture-handoff` `SKILL.md`, its `refs/template.md`)
  merely as tooling.
  If that skill is itself the subject of the work, reference it as content in the relevant section.
- Use caveman mode when writing the task doc to reduce words without losing signal.
