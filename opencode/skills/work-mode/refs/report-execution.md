# Execution report

Written at the stop of an execution unit.

```
<what the unit did and what it produced>

**<Section>**
<one to three sentences>

Next is <unit> — <why it is next>.

Say `next` or similar to continue.
```

## Rules

- The opening paragraph reports what the unit did and what it produced.
- Sections are optional and at most three, drawn from the menu below.
  When more than three apply, keep the three that most change the next move, and say how many were
  withheld.
- Prose, never `label: value` lines.
- The closing line names the next unit and why it is next.
- On the last unit, the closing line says nothing is next and what is left open.
  Drop the continue invitation.
- A unit that yields before its outcome is reached closes by naming the same unit and what is left
  of it, never the following unit, even on the last unit.
- A unit with no real decision and no open risk gets no sections at all.
  Padding the report to look thorough is a failure, not diligence.

## Sections

Ordered by how directly they change the next move.

- **Decisions** — what was chosen that could have gone another way, and why.
- **Rejected** — the path not taken, and what it would have cost.
- **Risks** — what is unverified, shaky, or likely to bite later.
- **Reflection** — what differed from expectation while doing the unit.
- **Approach** — what to change in how the rest gets done.

## Example

Units from the user's plan: read the status command and its tests / add the flag /
extend the tests / run the suite. The agent does the first unit.

```
Read src/status.ts and its test file. The flag belongs in the arg parser, and the reporter
already takes a verbosity level.

**Decisions**
Thread the flag through the existing level instead of adding new plumbing.

**Rejected**
A separate reporter method — duplicates the level logic.

**Risks**
Nothing covers a level above 2, and the tests may never exercise it.

Next is adding the flag and threading it into the output — the smallest step that proves
the path.

Say `next` or similar to continue.
```
