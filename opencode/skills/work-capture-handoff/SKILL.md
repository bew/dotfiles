---
name: work-capture-handoff
description: |
  Captures one deferred, explicitly-named work item from the current session as a small
  TASK-*, IDEA-*, or BUG-* note — an intent to do later, for a future user or agent to pick up.
  Three modes: `capture-task` writes TASK-*, `capture-idea` writes IDEA-*, and `capture-bug`
  writes BUG-*.
  Load in `capture-task` mode when the user defers a task unrelated to the current work, e.g.
  - deferral/reminder, like "defer/remember for later"
  - off-topic marker, like "unrelated, but …"
  - deferred intent, like "we'll come back to this"
  - explicit, like "LATER: …" or "TASK(<when>): …"
  Load in `capture-idea` mode when the user says `capture-idea`, or flags an idea as unrelated
  to the current work, like "unrelated idea: …".
  Load in `capture-bug` mode on `/bug-capture-handoff`, or on an explicit bug cue, like
  "file a bug", "that's a bug, note it", "BUG: …", or a defect flagged as unrelated to the
  current work.
  Never load in `capture-bug` mode on a bare mention of breakage ("it fails", "that looks wrong")
  — grill those first.
  Never load on a bare idea float ("what if…", "idea:", "could we…") — grill those first.
metadata:
  maintainers: [bew]
---

IMPORTANT: Do not invoke `compress` while producing this capture.
If a context compression is due, write the doc first, then compress.
Keep compression blocked even when the PLAN-mode guard halts the write —
release it only once the doc has actually been written.

## Setup — resolve inputs

Determine these from whatever is available in context
(user message, prior context, or defaults):

- **Mode**: `capture-task`, `capture-idea`, or `capture-bug`. Required — never inferred from the
  subject, and never switched between modes because the subject reads that way.
  Taken from the invoking command, from a `capture-task` cue (deferral, off-topic marker,
  `LATER: …`, `TASK(<when>): …`), from an explicit `capture-idea` phrase, from an explicit
  `capture-bug` phrase or bug cue, or from a task, idea, or defect the user flags as unrelated
  to the current work.
  If absent, stop and ask the user.
- **Subject**: what the capture is about — the task, the idea, or the bug.
  Required — never inferred.
  If absent, stop and ask the user.
- **Bug state** (`capture-bug` only): `open` or `confirmed`. Default `open`.
  Take `confirmed` from the user context or wording, e.g. "confirmed", "reproduced",
  "I can reproduce it", "already seen it happen".
  Ignore this input in the other modes.
- **Output dir** (`$dir`): the target project directory for the subject.
  Derive from the subject's content.
  If it does not map to a project/repo, ask the user.
  Never default to cwd.

**Ambiguous flag**: an unrelated aside with no explicit mode marker
(e.g. "unrelated, but what if we swapped the cache layer") matches task and idea alike.
Ask the user which mode applies before proceeding.
A defect flagged as unrelated resolves to `capture-bug` when it names something observed going
wrong; a speculative "it might break" is still a task or an idea.

**Unrelated-idea flag**: when the mode came from an unrelated-idea flag rather than the command
or an explicit `capture-idea`, ask the user first — file it now as an `IDEA-*` note, or handle it
later without a file.
If later: end this skill only — write nothing, say no file was created, then resume the
session's other work.
Do not stop the session or wait for further instruction.
If filed now: continue at *Step:Scan*.

State resolved values:

```text
Mode: <capture-task|capture-idea|capture-bug>
Subject: <value>
Bug state: <open|confirmed>   # capture-bug only
$dir: <resolved path>
```

**Vars used throughout**: (output them in context once known!)
- `$dir` — resolved output directory.
- `$date` — capture timestamp.
- `$existing` — existing files in `$dir` carrying `$filename`'s prefix.
- `$slug` — kebab-case label derived from the subject.
- `$filename` — `<TASK|IDEA|BUG>-$date-$slug.md`, per mode.
- `$template` — `./refs/template-bug.md` for `capture-bug`, `./refs/template.md` otherwise.

## Step 1 — Scan

Compute vars:
- `$date` — run `date +%Y%m%dT%H%M`.
- `$existing` — list existing `<TASK|IDEA|BUG>-*` files in `$dir`, matching the mode.
- `$slug` — derive from the subject. Kebab-case, max ~10 words.
  Never use `task`, `idea`, `bug`, `capture`, `session`, or `handoff` alone as the slug.
- `$filename` — `<TASK|IDEA|BUG>-$date-$slug.md`, per mode.

Scan the session for material pertaining to the subject only:

1. **Provenance**: what in the session triggered this subject.
2. **Subject-relevant decisions** and open sub-questions.
3. **Subject-relevant artefacts**: paths or URLs touched or needed to do it.
4. **The subject's own blockers or prerequisites** — anything that must happen first.

Drop everything else.
Do not carry blockers or prerequisites that belong to other unrelated threads.

## Step 2 — Write

NOTE: If the session is in PLAN mode: stop immediately.
Output: "Cannot write the capture in PLAN mode — switch to BUILD mode first, then re-run."
Do not proceed until the user has switched modes and re-requested.

If `$filename` is in `$existing`: adapt the filename (e.g. append a numeric suffix)
so nothing is overwritten.

Read `$template` for the required doc structure.
Write the capture to `$dir/$filename` with the `write` tool, without asking for confirmation.
When the mode is `capture-bug` and Bug state is `confirmed`, the H1 carries `[CONFIRMED]` ahead
of the symptom; otherwise it carries no tag.

If the write fails (e.g. `$dir` does not exist): tell the user and ask how to proceed.

After writing, tell the user:

> <Task|Idea|Bug> capture written to `<full path>` — open to inspect.

NEVER output the doc content inline.

## Rules

- ALWAYS write the capture with the `write` tool.
  Never output the doc content inline in the conversation.
- Do not inline file contents — reference by path only.
- ONLY include content relevant for the subject.
- ONLY reference URLs that were confirmed valid in the session.
- Run commands to get missing information (date, existing `<TASK|IDEA|BUG>-*` list) in one tool call,
  not multiple.
- NEVER include meta-commentary about the capture doc itself
  (e.g. "no other files were referenced", "this section does not apply").
  State content, not commentary about the doc.
- NEVER reference the skill or template that produced this capture
  (e.g. the `work-capture-handoff` `SKILL.md`, its `refs/template.md` or `refs/template-bug.md`)
  merely as tooling.
  If that skill is itself the subject of the work, reference it as content in the relevant section.
- Use caveman mode when writing the doc to reduce words without losing signal.
