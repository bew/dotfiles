# Handoff Doc Template

The handoff doc must contain the following sections in order.
Omit a section only if genuinely not applicable — state why.

---

## Context

One short paragraph.
What was this session about?
State: repo name, working directory, current branch (if determinable).

## What was done

Bulleted list of completed work.
Each item: what changed + which file/artefact + why.
Reference files by path.
Do not inline file contents.
If work is already captured in a commit, spec, or issue: reference that artifact instead of repeating it.

## What remains

Bulleted list of pending or in-progress work.
Source from open/in-progress todos if available; fill gaps from conversation scan.
Mark items **Blocking** or **Non-blocking** relative to the stated Focus.

## Open questions

Unresolved decisions the continuation agent or human must address.
Each entry: statement of the decision, **Blocking** or **Non-blocking**, brief rationale.

## Suggested skills

List of skills the continuation agent should load.
For each: skill name + one line on why it is relevant to what remains.
Omit skills used in this session but not needed for what remains.

## Key files

Paths directly relevant to what remains.
One-line description per file.
Omit files the continuation agent won't need to touch.

---

## Optional sections (include only if applicable)

### Subagent outcomes

If subagents were launched and their results are not already in "What was done":
summarise each subagent's task and result.

### Redactions

Note any sensitive information encountered and omitted from this doc.
