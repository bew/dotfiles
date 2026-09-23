---
name: handoff
description: |
  Produces a structured handoff document from the current session
  so another agent or human can continue the work.
  Defers context compression until the handoff doc is written.
  Not for direct use — invoked via command only.
metadata:
  maintainers: [bew]
---

IMPORTANT: Do not invoke `compress` while producing this handoff.
If a context compression is due, write the handoff doc first, then compress.
Keep compression blocked even when the PLAN-mode guard halts the write —
release it only once the handoff doc has actually been written.

## Setup — resolve inputs

Determine the following values from whatever is available in context
(user message, prior context, or defaults):

- **Focus**: what the next session will work on.
  Extract from user message or context.
  Default: `(none)` — produce a generic full-session handoff.
- **Output dir** (`$outputdir`): where to write the file.
  Default: current working directory.
  If the cwd appears unrelated to the handoff content, ask the user for the target dir.

Ask the user for any input that cannot be inferred and that meaningfully affects the output.
Do not ask for Focus if the session topic is unambiguous.

State resolved values before proceeding:

```text
Focus:      <value or "(none)">
$outputdir: <resolved path>
```

**Vars used throughout**: (output them in context once known!)
- `$outputdir` — resolved output directory.
- `$date` — today's date in `YYYYMMDD` format.
- `$slug` — kebab-case label derived from what is being worked on.
- `$filename` — `HANDOFF-$date-$slug.md`

## Step 1 — Scan

Compute vars:
- `$date` — run `date +%Y%m%d`.
- `$existing` — list existing `HANDOFF-*` files in `$outputdir`.
- `$slug` — derive from Focus, session title, or dominant topic.
  Kebab-case, max ~5 words.
  Never use `session` as a slug — always derive from actual content.
- `$filename` — `HANDOFF-$date-$slug.md`

Scan the current session for material to include in the handoff doc.

1. **Todos**: check for remaining todo items in the session.
2. **Conversation scan**: scan for decisions made, files changed, artefacts created or updated,
   errors encountered, and open threads not captured in todos.
3. **Subagents**: collect all `task` tool calls and their returned results.
   Do not re-launch subagents.
   Surface outcomes that are not already captured in "What was done".
4. **Open questions**: collect unresolved decisions surfaced in the conversation.
5. **Skills loaded**: note skills that were loaded or referenced.
   Retain only those relevant to what remains.

If Focus was given: weight surfacing toward that area.
Do not exclude blockers or prerequisites from other areas.

## Step 2 — Write

NOTE: If the session is in PLAN mode: stop immediately.
Output: "Cannot write the handoff doc in PLAN mode — switch to BUILD mode first, then re-run."
Do not proceed until the user has switched modes and re-requested.

If `$filename` already exists: adapt the filename (e.g. append a numeric suffix)
so nothing is overwritten.

Write the handoff doc to `$outputdir/$filename` using the `write` tool,
without asking for confirmation.
Read <./refs/template.md> for the required doc structure.

If the write fails (e.g. output dir does not exist): tell the user and ask how to proceed.

After writing, tell the user:

> Handoff doc written to `<full path>` — open to inspect.

Do not output the doc content inline.

## Rules

- Always write the handoff doc with the `write` tool.
  Never output the handoff content inline in the conversation.
- Do not inline file contents — reference by path only.
- Only reference URLs that were confirmed in the session
  (appeared in user messages or tool results).
  Never reference URLs invented or hallucinated by the agent.
- When instructing the reader to load a skill, use one of two forms:
  ``load `foo` skill`` for an unconditional load, or
  ``load `foo` skill when <condition>`` for a conditional one.
  Conditional refs must carry the `when <condition>` clause.
  Write these refs verbatim — caveman mode must not compress `load` or `skill` away.
  Skill mentions that are not load instructions (e.g. in `What was done`) stay prose.
  Governs skill names only, not raw skill dir/file paths — those stay plain path refs.
  Never write a bare or ambiguous ref (e.g. ``see `foo` `` or a bare `` `foo` — why `` bullet).
  Sentence-initial `Load` is fine.
- Keep the doc readable by a human.
  Do not assume the reader is an agent.
- Never write to a path outside the resolved `$outputdir` without explicit user confirmation.
- On filename collision, adapt the filename rather than overwriting.
- Run commands to get missing information (date, existing HANDOFF list)
  in one tool call, not multiple.
- Never include meta-commentary about the handoff doc itself
  (e.g. "no other files were referenced", "findings are consolidated above",
  "this section does not apply"). State content, not commentary about the doc.
- Never reference the skill or template that produced this handoff
  (e.g. the `handoff` / `handoff-standalone` `SKILL.md`, its `refs/template.md`)
  merely as tooling. If that skill is itself the subject of the work,
  reference it as content in the relevant section.
- Use caveman mode when writing the handoff doc to reduce words without losing signal.
