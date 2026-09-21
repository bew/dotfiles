---
name: handoff-standalone
description: |
  Self-contained export of `handoff` for ad-hoc loading into tool-less chat contexts.
  All instructions inlined — no external files.
metadata:
  maintainers: [bew]
---

# Handoff

Produce a structured handoff document from a work session,
so another agent or human can continue the work.

## Step 1 — Setup

Determine these from whatever is available in context
(user message, pasted session, prior context):

- **Focus**: what the next session will work on.
  Default: `(none)` — produce a generic full-session handoff.
- **Date** (`$date`): today's date in `YYYYMMDD` form, if stated in context.
  If absent: omit the date.

Ask the user for any input that cannot be inferred and that meaningfully affects the output.
Do not ask for Focus if the session topic is unambiguous.

State resolved values in one line before proceeding.

**Vars used throughout**:
- `$date` — today's date in `YYYYMMDD`, or none.
- `$slug` — kebab-case label derived from what is being worked on.
- `$filename` — `HANDOFF-$date-$slug.md`, or `HANDOFF-$slug.md` when `$date` is absent.

## Step 2 — Scan

Derive `$slug` from Focus, session title, or dominant topic.
Kebab-case, max ~5 words.
Never use `session` as a slug — always derive from actual content.

Scan the available session material for content to include in the handoff.

1. **Decisions**: choices made and their rationale.
2. **Changes**: files, artefacts, or docs created, changed, or deleted.
3. **Errors**: failures encountered and their resolution state.
4. **Open threads**: unresolved work not captured elsewhere.
5. **Open questions**: decisions surfaced but not settled.
6. **Skills and tools referenced**: names the continuation may need.
   List what you can identify; flag that tool-less generation may have missed some.

If Focus was given: weight surfacing toward that area.
Do not exclude blockers or prerequisites from other areas.

## Step 3 — Output

If a file-writing tool is available: write the handoff doc to `$filename` in the current working
directory.
Do not also emit the content inline.

Otherwise: emit the handoff document inline in a fenced `md` block, and give `$filename` as the
suggested filename for the reader.

Structure the doc per *Handoff doc structure* below.

## Handoff doc structure

The handoff doc must contain the following sections in order.
Open with the Tool-access notice.
Omit a section only if genuinely not applicable — state why.
In the output doc these are top-level `##` headings.

### Tool-access notice

State at the very top that this handoff was generated in a tool-less or limited-tool context.
Mention that relevant skill and tool names to load may be missing or incomplete.
Instruct the reader to suggest the skills and tools needed, and to ask the user before proceeding.

### Context

One short paragraph.
What was this session about?
State: repo name, working directory, current branch (if already known, skip otherwise).

### What was done

Bulleted list of completed work.
Each item: what changed + which file/artefact + why.
Reference files by path.
Do not inline file contents.
If work is already captured in a commit, spec, or issue:
reference that artefact instead of repeating it.

### What remains

Bulleted list of pending or in-progress work.
Mark items **Blocking** or **Non-blocking** relative to the stated Focus.

### Open questions

Unresolved decisions the continuation agent or human must address.
Each entry: statement of the decision, **Blocking** or **Non-blocking**, brief rationale.

### Suggested skills and tools

List the skills and tools the continuation agent should consider.
For each: name + one line on why it is relevant to what remains.
Plain recommendations only — no load syntax.
Omit items used in this session but not needed for what remains.

### Key artefacts

Artefacts directly relevant to what remains:
local/remote files, reference URLs, docs, specs, issues, PRs.

One-line description per entry, with a locator (path or URL) where known.
Omit artefacts the continuation agent won't need.

### Optional sections

Include only if applicable.
- **Subagent outcomes**: if the session material mentions subagent/task runs and their results are
  not already in "What was done", summarise each task and result.
- **Redactions**: note any sensitive information encountered and omitted from this doc.

## Rules

- Open the doc with the Tool-access notice.
- Do not inline file contents — reference by path only.
- Only reference URLs confirmed in the session.
  Never reference invented or hallucinated URLs.
- Name skills and tools as plain recommendations.
- Keep the doc readable by a human.
  Do not assume the reader is an agent.
- Prefer writing to a local file when a file tool is available;
  emit inline only when it is not.
- Write terse — cut words without losing signal.
