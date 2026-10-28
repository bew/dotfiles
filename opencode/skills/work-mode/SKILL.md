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
  Applies inside a skill that runs its own phased workflow: its phases are never units, and the
  mode ends at the phase boundary.
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
  a numbered list the user gave, named steps in an active skill, never its phases.
  Use them as-is. Do not re-cut or re-derive them.
- In a phased skill, units come from the plan inside the current phase.
  Phase names are never units, even when they read like named steps.
  The set of phases never stands in for the plan.
- No units in context: propose them, one line each, then stop.
  In a phased skill, derive them from the phase body; deriving them is not re-cutting.

### Walkthrough slices

- A slice is one seam of the subject: a file, a module, a layer, a step in the call path.
- Slice on seams first. No clear seams: slice by what the reader must understand in order.
- A slice is read-only. It ends when that part is explained.
- Name the slice taken and the one after it, so the reader knows the route.
- Show the slice plan first, one line per slice, then stop.

## Stops

Work stops on any of these.

- **Unit finished.** Report, then stop.
- **Phase gate.** The active skill reaches the end of a phase, on the phase's own exit signal: a
  gate prompt, the choice question the phase ends on, or a confirmation it waits on.
  Stop on that exit signal and close on it.
  Name every unfinished unit and say it is dropped.
  The mode ends here, and applies again only when the user restates it for the next phase.
  A phase with no exit signal still ends the mode at its boundary.
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

Every stop that follows a unit ends with a report, and so does a phase gate.
Two stops have their own shape instead: a blocker is one line, and a proposal of units or a slice
plan is the list itself.
At a phase gate, the report closes on the phase's exit signal when there is one, even when the
plan's units ran out. With no signal, it closes as the last unit would.
Read one file at each report or slice-plan stop:
- Read <./refs/report-execution.md> in execution mode, after a unit or at a phase gate.
- Read <./refs/report-walkthrough.md> in walkthrough mode, after a slice, at a slice plan, or at a
  phase gate.

Do not write a report from this file alone.

## Relation with phased skills

Execution mode applies to a skill that runs its own phased workflow, such as `opencode-crafter`,
`write-spec`, or `design-exploration`, within the phase boundaries below.

- Entering a phase: units are the phase's plan, derived from its body and proposed when it has
  none. That proposal is the first stop, ahead of the phase's own first action.
- Within a phase: one unit at a time, on the same stops.
- Exiting a phase: the mode ends at the boundary, on that phase's exit signal when it has one.
- Moving back to an earlier phase: the mode survives. Only a forward phase boundary ends it.

Walkthrough mode reads a phase differently, since a phase is part of the subject:
a slice may seam on one; a phase gate of the active skill still stops the walkthrough, and the mode
ends there.
