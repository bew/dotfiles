---
name: handoff
description: |
  Produces a structured handoff document from the current session
  so another agent or human can continue the work.
  Not for direct use — invoked via command only.
metadata:
  maintainers: [bew]
---

## Setup — resolve inputs

Determine the following values from whatever is available in context
(user message, prior context, or defaults):

- **Focus**: what the next session will work on.
  Extract from user message or context.
  Default: `(none)` — produce a generic full-session handoff.
- **Output dir** (`$outputdir`): where to write the file.
  Default: git repo root (`git rev-parse --show-toplevel`).
  If not in a git repo, fall back to current working directory.

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
- `$slug` — derive from Focus, session title, or dominant topic.
  Kebab-case, max ~5 words. Never use `session` as a slug — always derive from actual content.
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

Before writing: check that `$outputdir/$filename` does not already exist.
If it does: tell the user and ask how to resolve (different slug, abort, or explicit overwrite).
Never silently overwrite an existing handoff file.

Write the handoff doc to `$outputdir/$filename` using the `write` tool.
Read <./refs/template.md> for the required doc structure.

After writing, tell the user:

> Handoff doc written to `<full path>` — open to inspect.

Do not output the doc content inline.

## Rules

- Do not inline file contents — reference by path only.
- Only reference URLs that were confirmed in the session (appeared in user messages or tool results).
  Never reference URLs invented or hallucinated by the agent.
- Keep the doc readable by a human.
  Do not assume the reader is an agent.
- Never write to a path outside the resolved Output dir without explicit user confirmation.
- Never overwrite an existing handoff file — resolve conflicts before writing.
- The handoff file must not be git-tracked.
- Use caveman mode when writing the handoff doc to reduce words without losing signal.
