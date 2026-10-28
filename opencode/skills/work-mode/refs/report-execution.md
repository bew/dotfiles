# Execution report

Written at the stop of an execution unit, or at a phase gate.

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
- At a phase gate, the report closes on the phase's exit signal instead of the next unit, even when
  the plan's units ran out.
  These phase rules override the last-unit and yield rules above.
  The report says the mode ends with the phase, in one sentence.
  That sentence is never a question and never restates the gate's invitation.
  A phase with no exit signal closes on the normal rules, and still says the mode ends with the
  phase.
  When the signal is a choice question or a confirmation, the skill's own emission, with any
  prelude it requires, follows the report, and the report never restates it.
- At a phase gate reached with a unit unfinished, the opening paragraph names every unfinished unit
  and says it is dropped.
- A unit with no real decision and no open risk gets no sections at all.
  Padding the report to look thorough is a failure, not diligence.

## Sections

Ordered by how directly they change the next move.

- **Decisions** — what was chosen that could have gone another way, and why.
- **Rejected** — the path not taken, and what it would have cost.
- **Risks** — what is unverified, shaky, or likely to bite later.
- **Reflection** — what differed from expectation while doing the unit.
- **Approach** — what to change in how the rest gets done.

## Examples

### Unit

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

### Phase gate

Units from the phase's plan: fill sections 1 and 2 / fill section 3 / run the review pass.
`Phase:Draft` ends on its gate prompt after section 3.

```
Filled sections 1 and 2 of the spec. Section 2 needed the storage model settled first.

**Decisions**
Store offsets instead of line numbers — the parser drops line boundaries.

**Risks**
Section 3 leans on an index shape nothing has fixed yet.

`Phase:Draft` is done and the mode ends here.

Ready to move to `Phase:Review`? (say 'next' or similar to proceed)
```

The same phase, where section 3 was still blocked when the gate arrived:

```
Filled sections 1 and 2 of the spec, then stopped on section 3, which waits on the index shape.
Section 3 is dropped.

`Phase:Draft` is done and the mode ends here.

Ready to move to `Phase:Review`? (say 'next' or similar to proceed)
```
