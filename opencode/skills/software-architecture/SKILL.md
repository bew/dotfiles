---
name: software-architecture
description: |
  Internal structure of code: module roles, seams, value ownership, splitting a mutating operation,
  and representing failure.
  Load to design new structure, or to judge and rework existing structure — "this class is doing
  too much", "why is this hard to test", "everything reads the database directly".
  Load when flags or state have piled up, when a design review asks what is good or bad about the
  current structure, or when two shapes both look plausible.
  Not for: deployment topology, technology selection, performance tuning.
  Not for: naming, types, comments, error mechanics (propagation, logging, exit codes, retry
  implementation); representing a failure as data is in scope — see "Decide failure behaviour".
metadata:
  maintainers: [bew]
---

## Goal

Decide and defend the internal structure of code, so the result is readable, testable, and carries
no avoidable coupling.

REQUIRES: load `software-vocabulary` skill — it defines all structural terms used throughout.

## Scope

Decisions covered here:
- which concepts are load-bearing, and what each becomes in code
- what shape the data takes, and which values are data versus side-effects
- where the seams are, and which adapter occupies each
- what owns state, and what is derived from it
- how an operation splits between deciding and changing
- how failure is represented, and whether partial progress survives

Hand off elsewhere:
- naming, type-system design, comments, error-handling mechanics — `coder-generic` and the
  `coder-*` skills
- a durable design document and its lifecycle — `write-spec`
- maturing an idea before it is a design at all — `design-exploration`

## Which case

Judge which case you are in first: it decides what you produce, and a fork can land while working
the frames.

- Nothing built yet? Work the frames, write the report, close with the next moves that fit.
- Architecture review asked for, or structure exists and part of it is changing with no settled
  design for that change?
  Work the frames against the code as it is, report it with a flaw wherever a paragraph has one,
  and index the changes after the sections.
  A partial change scopes the report to what it touches, and keeps the headings the change reaches.
  A section with nothing to say about it is left out, not emptied: an empty section still means a
  decision nobody made.
- Two shapes compete, and the ask is which one? Read <./refs/design-it-twice.md>, recommend one.
- Writing code to a decided design, even when that code reshapes the structure?
  The rules below bind; there is nothing new to decide.

## Design frames

These frames are decisions to make, not a procedure to perform. Work through them in this order.
The sequence carries information: the data shape constrains the seams, and the failure behaviour
depends on where the seams landed.
In a review, reflect on each frame of the code as it is: the answer is a claim about what exists,
not about what should.

A frame that lands on two plausible shapes is a fork.
The usual kinds are a `contract` shape, a data shape, and a module split.
Read <./refs/design-it-twice.md> before moving on, and say what the pick gives up.

The frames end with a report: `<thing> Architecture Report`, where `<thing>` is what the report
covers — the repo, a module, or a script.
Sections, each under its own heading, with every paragraph opening with `**Term**: ` and continuing
one sentence per line, never restating its lead-in:
- `Concepts` — what each load-bearing thing means, what it becomes in code, what it is not.
- `Data` — what makes each thing valid, what identifies it, and what is derived rather than held;
  no frame decides these, so state the choice behind it.
- `Modules` — each module's role, what callers may rely on, and whether it is a seam.
- `Failure` — per step, expected or exceptional, and what survives.

The report describes the structure, not the frames: a module and its contract belong in it even
though no frame names them.
A section silent on a decision the frames require is a decision nobody made.

A review reports the code as it is.
A paragraph with a flaw closes with one sentence on what is not good there, naming no fix — the
fixes are the changes.
Then `Suggested changes` holds one line per main change, numbered `C1`, `C2` …, the line reading
as the heading it would expand into.
A new design report has no `Suggested changes` section.
A closing paragraph of that section carries the minors, opening with `**Minors**: ` and listing
them in prose.
`No changes suggested.` is the whole section when a review finds nothing worth changing.
A change expands only when asked, into what moves, what it replaces, what forces it, and what it
costs — no code beyond what the entry is unreadable without.
Main changes are taken up one at a time, by asking.

Close the report with one line per next move, each `Say '<cta>' to <short description>`, drawn from:
- `discuss changes` — write a short subsection per main change, then walk the changes one at a
  time, asking per change, the minors paragraph last; a review holding only minors walks that
  paragraph instead.
- `rework <part>` — redo one part of the report.
- `apply all` — implement every change in code.
- `to file` — save the report where the user says.

A review with changes offers all of them.
A review without changes offers `rework <part>` and `to file`, as does a new design.
The form is fixed, the set is not: add a move when a case earns one.

The report stays in conversation; write it to a file only when the user agrees and names the
location.

### Identify the load-bearing concepts

A concept is load-bearing when removing it collapses the structure into ad-hoc code around it.
Name each one; naming is how the identification sticks.
If two things share a representation but differ in meaning, they are two concepts.

### Decide the data shape

Variation that arrives whole wants data, not a flag threaded through call sites.
See <./refs/patterns/data-over-flags.md>, and
<./refs/patterns/explicit-decision-table.md> when the variation is a closed set of states with
illegal combinations.
No frame settles what makes a thing valid, what identifies it, or what is derived rather than
held: those are decided ad hoc for the run — pick a way, and say which way you picked in the
report.

### Split reading from changing

Ask what the code observes and what it changes.
A mutating `operation` separates the decision — what will change — from the `orchestrator`
that performs it.
See <./refs/patterns/detect-plan-apply.md>.

### Place the seam

Find what is slow, non-deterministic, or external, and cut there.
A seam is a decision, not a leftover: it fixes what can be tested without the outside world.
Justify it by a real second adapter, or by a side-effect already substituted in tests.
A seam with one hypothetical adapter demands knowledge and delivers no swappable behaviour.
When two structures both satisfy the patterns, prefer the one with the smaller contract for the
same behaviour — the module behind that thin contract is deep, because the behaviour sits
behind it.
See <./refs/patterns/side-effects-at-the-edge.md>.

### Decide failure behaviour

For each step, decide whether failure is expected (a returned value) or exceptional (abort), and
whether partial progress survives.
Undecided failure behaviour reappears as scattered `try` blocks and half-applied state.

## Rules

*Place the side-effects*
- `logic` must not read the clock, environment, filesystem, or network directly.
  Pass those values in, or move the access behind an `adapter` at the edge.

*Own the values*
- One value has one `owner`; every other reader derives from it.
  Keep `local state` inside its module.
  Copies are allowed only when derived and disposable, and recomputing a small derived value beats
  keeping a copy.
- A closed set — the `lifecycle` states of one thing, or the cases of one decision — must be a
  named type, not a primitive with a comment.
- Never let a design decision stay implicit in the code shape.
  State the choice and its cost when proposing structure.

*Keep modules whole*
- A module owns a concept family: several related items that change together.
  A module holding one class or two functions is a `fragment`; fold it into its nearest owner.
- Split on a shared collaborator set, a shared failure contract, or a part that is deletable.
  Never one module per verb, per class, or per kind of code.
- A kind-directory (`data/`, `adapters/`, `orchestrators/`) pays off only when each kind holds
  several modules; below that it is import noise.
- Separate data from behaviour per class, not per file.
  A `data module` derives values and never acts; an `orchestrator` orders calls and holds no
  domain `logic`.

*Land the change*
- A mutating `operation` must expose a step that has no side-effects and computes what will change.
  Tests assert that step; the `orchestrator` stays thin.
- Callers and tests cross the same `contract`.
  A test that reaches past it is testing an implementation, and any refactor breaks it.
- When a `contract`-level test lands, delete the tests it replaces.
  Two test tiers for the same behaviour outlive their purpose.

## Patterns

Judge a `deep module` by deletion — remove it and see what happens.
If the complexity vanishes, it was a pass-through and the design is better without it.
If the complexity reappears across its callers, it earned its keep.

Read a pattern file only when its row fires or a frame names it; the catalogue is a set of
situations, not a checklist.

| Pattern | Read when … |
|---|---|
| <./refs/patterns/detect-plan-apply.md> | … an `orchestrator` must decide which operations to run from the current state. |
| <./refs/patterns/side-effects-at-the-edge.md> | … `logic` needs the world to run or test. |
| <./refs/patterns/explicit-decision-table.md> | … a `lifecycle` is encoded as booleans, or a decision tree is scattered. |
| <./refs/patterns/data-over-flags.md> | … a flag or mode string travels down several stackframes, carried unused. |
| <./refs/patterns/named-cases-over-booleans.md> | … a boolean parameter hides which behaviour it picks, or two booleans combine. |
| <./refs/patterns/single-source-of-truth.md> | … a value is stored or decided twice. |
| <./refs/patterns/data-vs-behaviour.md> | … a data type grows a method that writes or orders, or an orchestrator is written as a record of fields. |
| <./refs/patterns/module-granularity.md> | … a split is proposed and the module count outgrows the concept count. |
