---
name: work-mode
description: |
  Load when the user sets a session work mode, in one of two forms.

  Execution: "work on this step by step", "one at a time", "work with me" — the work proceeds
  one unit at a time, then stops.

  Explanation: "walk me through <subject>" — the subject is explained one slice at a time, then
  stops. This form wins when both appear.

  A mode statement about execution concerns how the work proceeds, not what the deliverable
  contains, and not a passing aside such as "work with me here".
  Not for skills that run their own phased workflow.
  Applies to every kind of work: code, research, writing, ops, read-only included.
metadata:
  maintainers: [bew]
---

# Work mode

One unit of work, then a stop worth reading.

## Triggers

- `step by step`, `one at a time`, `work with me` — execution mode.
- `walk me through <subject>` — walkthrough mode.
- Both present: walkthrough wins.
- A mode statement governs how the work proceeds: the user wants one unit at a time.
- A phrase about the deliverable, or a passing aside such as "work with me here", is not a mode
  statement.
- No mode stated: this skill does not apply.

## Units

A unit is either an execution unit or a walkthrough slice.
Both obey the same stops.
A unit ends at a checkable outcome.

### Execution units

- Units come from context when it defines them: an approved plan, a recap, a spec's milestones,
  a numbered list the user gave, named steps in an active skill.
  Use them as-is. Do not re-cut or re-derive them.
- No units in context: propose them, one line each, then stop.

### Walkthrough slices

- A slice is one seam of the subject: a file, a module, a layer, a step in the call path.
- Slice on seams first. No clear seams: slice by what the reader must understand in order.
- A slice is read-only. It ends when that part is explained.
- Name the slice taken and the one after it, so the reader knows the route.
- Show the slice plan first, one line per slice, then stop.

## Stops

Work stops on any of these.

- **Unit finished.** Report, then stop.
- **Decision that cannot wait.** Some outcome-affecting choices invalidate work already done in the
  unit if deferred. Present the choice and the options that matter, then stop.
  Resume the same unit after the answer.
- **Blocker.** Say what blocks, in one line. Then stop.
- **Forced yield.** The outcome cannot be reached before you have to yield: context limit, a build
  that outlives the response, a tool waiting on the user.
  Say so and report partial progress. Do not pretend the unit is done.

At any stop:

- Never start the next unit, however small, obvious, or nearly finished it looks.
- Do not merge units to finish sooner.
- Do not widen the unit to route around a blocker.
- Do not quietly downgrade the unit's outcome to keep going.

## Report

Every stop after a unit ends with a report.
Two stops have their own shape instead: a blocker is one line, and a proposal of units or a slice
plan is the list itself.
Read one file at each report or slice-plan stop:

- Read <./refs/report-execution.md> when the stop follows an execution unit.
- Read <./refs/report-walkthrough.md> when the stop follows a walkthrough slice, or when showing a
  slice plan.

Do not write a report from this file alone.

## Phased workflow skills

Never apply this mode to a skill that runs its own phased workflow, such as `committer`,
`write-spec`, or `opencode-crafter`.
Such a skill defines its own phases and gates, and the mode does not apply while it runs.
Follow that skill's workflow, and say the mode was dropped.
