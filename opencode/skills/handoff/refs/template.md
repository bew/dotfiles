# Handoff Doc Template

The handoff doc must contain the following sections in order.
Omit any section that has no qualifying content — do not keep an empty heading
or write filler (e.g. "none", "N/A", "nothing to report").

---

## Context

One short paragraph.
What was this session about?
State: repo name, working directory, current branch (if already known, skip otherwise).

## What was done

Bulleted list of completed work.
Each item: what changed + which file/artefact + why.
Reference files by path.
Do not inline file contents.
If work is already captured in a commit, spec, or issue:
reference that artefact instead of repeating it.

## What remains

Bulleted list of pending or in-progress work.
Source from open/in-progress todos if available; fill gaps from conversation scan.
Mark items **Blocking** or **Non-blocking** relative to the stated Focus.

## Open questions

Unresolved decisions the continuation agent or human must address.
Each entry: statement of the decision, **Blocking** or **Non-blocking**, brief rationale.

## Suggested skills

List of skills the continuation agent should load.
For each: write ``load `foo` skill`` + one line on why it is relevant to what remains.
Use ``load `foo` skill when <condition>`` when the load is conditional.
Omit skills used in this session but not needed for what remains.

## Key artefacts

Artefacts the continuation agent must open or act on:
local/remote files, reference URLs, docs, specs, issues, PRs, etc.
One-line description per entry, with a locator (path or URL) where known.
Never restate information already covered in another section.

---

## Optional sections (include only if applicable)

### Subagent outcomes

If subagents were launched and their results are not already in "What was done":
summarise each subagent's task and result.

### Redactions

Note any sensitive information encountered and omitted from this doc.
