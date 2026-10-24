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
  Load in `capture-bug` mode on an explicit bug cue, like "file a bug", "that's a bug, note it",
  "BUG: …", or a defect flagged as unrelated to the current work.
  Never load in `capture-bug` mode on a bare mention of breakage ("it fails", "that looks wrong")
  — grill those first.
  Never load on a bare idea float ("what if…", "idea:", "could we…") — grill those first.
metadata:
  maintainers: [bew]
---

IMPORTANT: Do not invoke `compress` while producing this capture.
If a context compression is due, write the doc first, then compress.
Keep compression blocked even when the PLAN-mode guard halts the write — a halt is not an exit.
Release it only once the doc has been written, or when the skill exits with no doc
(the unrelated-idea "later" answer).

## Setup — resolve inputs

Determine these from whatever is available in context
(user message, prior context, or defaults):

- **Mode**: `capture-task`, `capture-idea`, or `capture-bug`. Required.
  The first source that sets it wins — never reclassify afterwards.
  Taken from the invoking command, from a `capture-task` cue (deferral, off-topic marker,
  `LATER: …`, `TASK(<when>): …`), from an explicit `capture-idea` phrase, from an explicit
  `capture-bug` phrase or bug cue, or from a task, idea, or defect the user flags as unrelated
  to the current work.
  `$worktype` follows from the mode: `TASK` for `capture-task`, `IDEA` for `capture-idea`,
  `BUG` for `capture-bug`.
  If absent, stop and ask the user.
- **Subject**: what the capture is about — the task, the idea, or the bug.
  Required — never inferred.
  If absent, stop and ask the user.
- **Bug state** (`capture-bug` only): `open` or `confirmed`. Default `open`.
  Take `confirmed` from the user context or wording, e.g. "confirmed", "reproduced",
  "I can reproduce it", "already seen it happen".
  Ignore this input in the other modes.
- **Dependencies** (optional): what the subject explicitly waits on, each as `<kind>:<slug>`,
  with `kind` one of `task`, `idea`, `bug`, or `spec`
  (e.g. `task:parse-frontmatter`, `idea:try-a-different-cache`, `bug:parser-drops-eof`,
  `spec:task-scopes`).
  Take only references stated in the user context — never infer or invent one.
- **Output dir** (`$dir`): the target project directory for the subject.
  Derive from the subject's content.
  If it does not map to a project/repo, ask the user.
  Never default to cwd.

**Unrelated flag**: resolve it in this order, first match wins.
1. Explicit idea marker ("unrelated idea: …") resolves to `capture-idea`.
2. Names something observed going wrong resolves to `capture-bug`.
3. Anything else ("unrelated, but …") — ask the user whether it is a task, an idea, or a bug.
   A speculative "it might break" is not observed breakage — it reaches rung 3.

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
Dependencies: <refs|none>
$dir: <resolved path>
```

**Vars used throughout**: (output them in context once known!)
- `$dir` — resolved output directory.
- `$worktype` — `TASK`, `IDEA`, or `BUG`, from the mode.
- `$created_at` — capture timestamp, `YYYYMMDDThhmm`.
- `$slug` — kebab-case label derived from the subject.
- `$filename` — `$worktype-$slug.md`.
- `$depends_on` — optional `depends-on` value: refs sorted by kind then slug, joined with ` & `.
- `$template` — <./refs/template-bug.md> for `capture-bug`, <./refs/template.md> otherwise.

## Step 1 — Scan

Compute vars:
- `$created_at` — run `date +%Y%m%dT%H%M`.
- `$slug` — derive from the subject. Kebab-case, max ~10 words.
  Never use `task`, `idea`, `bug`, `capture`, `session`, or `handoff` alone as the slug.
- **Slug collision**: if `$dir` already holds `$worktype-$slug.md`, name that file, ask the user
  for a different slug, and re-derive `$slug` and `$filename` from the answer.
  Wait for the answer before writing.
- `$filename` — `$worktype-$slug.md`.
- `$depends_on` — from Dependencies: keep only refs shaped `<kind>:<slug>`, with `kind` one of
  `task`, `idea`, `bug`, or `spec`, and `slug` bare kebab-case — no `TASK-`-style prefix,
  no `.md` suffix, no `:`, no whitespace.
  Drop a ref to the capture itself (`<kind>:$slug`).
  If Dependencies names a ref you would drop, list it and ask the user before writing.
  Never drop a stated ref silently.
  Rebuild `$depends_on` from the user's answer before writing.
  Dedupe silently — a repeated ref is the same edge.
  Sort lexicographically by kind then slug, join with ` & `.
  Leave unset when there are none.

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

Read `$template` for the required doc structure.
Write the capture to `$dir/$filename` with the `write` tool, without asking for confirmation.
The file opens with the frontmatter block: `created-at` set to `$created_at`, then `depends-on`
set to `$depends_on` only when that var is set.
When the mode is `capture-bug` and Bug state is `confirmed`, the H1 carries a trailing
`[CONFIRMED]` after the symptom; otherwise it carries no tag.

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
- Every capture carries the frontmatter block above its H1 and never a dated filename.
- Never overwrite an existing `$worktype-$slug.md`, and never append a numeric suffix.
  A taken slug goes back to the user for a new one.
- Run `date` once for `$created_at` — never re-derive the timestamp later.
- NEVER include meta-commentary about the capture doc itself
  (e.g. "no other files were referenced", "this section does not apply").
  State content, not commentary about the doc.
- NEVER reference the skill or template that produced this capture
  (e.g. the `work-capture-handoff` `SKILL.md`, its `refs/template.md` or `refs/template-bug.md`)
  merely as tooling.
  If that skill is itself the subject of the work, reference it as content in the relevant section.
- Use caveman mode when writing the doc to reduce words without losing signal.
