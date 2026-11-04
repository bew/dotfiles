# design-process — exploration

How the skill drives design work: our five "design moves", their parallel design-it-twice protocol,
and what "refinement" actually does.

## Findings

- Our draft has five unordered moves: name the concepts, split reading from changing, decide the data
  shape, place the seam, decide failure behaviour. No sequence, no output.
- Their skill has almost no process — one protocol: `DESIGN-IT-TWICE`.
  Frame constraints → spawn 3+ subagents, each with a different constraint
  (minimise interface / maximise flexibility / optimise the common caller / ports-and-adapters) →
  present sequentially → compare on depth, locality, seam placement → give an opinionated
  recommendation.
- `DESIGN-IT-TWICE` assumes subagents and a ticketed interface to redesign; it is useless without a
  concrete module to deepen.
- "Refinement" in our draft promises critique and refactor-driving but supplies no method.

## Design crux

A design skill either teaches judgement (moves) or runs a procedure (protocol).
We have the first and no way to execute it; they have one narrow executable procedure and no general
judgement.

## Decisions

### (settled) `moves-ordered-pass` — five moves in a fixed order, ending in a report

related-to: `architecture-report-shape`

The pass order: identify the load-bearing concepts, decide the data shape, split reading from changing,
place the seam, decide failure behaviour.
Order carries information — the data shape constrains the seams, and the failure behaviour depends on
where the seams landed.
The pass ends with a `<thing> Architecture Report`, whose sections and completion test are settled in
`EXPLO-output-structure.md`.
That report is the completion test the unordered list never had.

`Identify` covers the finding; naming the concept is how the identification sticks, so the move's own
text carries the naming act rather than the heading.
`Load-bearing` is the filter — remove the concept and the structure collapses into ad-hoc code around
it — and it stays inline in the move, not in the vocabulary, because it is a test applied to a noun.

#### Example

```pseudocode
modules:  parser (module) -> plan (data) -> apply (orchestrator) -> fs adapter
contracts: parse(text) -> Plan ; apply(Plan, Fs) -> Result
seams:    fs (two adapters: real, in-memory) ; clock (substituted in tests)
failure:  parse errors returned as data ; apply aborts on first error, no partial writes
```

### (settled) `refinement-runs-pass-in-review-mode` — critique is the same pass, against existing code

related-to: `architecture-report-shape`

A review runs the same five moves in the same order against the existing code, and each answer is a
claim about what exists rather than about what should.
No second procedure: one list of design questions, used forwards or backwards.
A refinement is a review scoped to what the change touches.
The report carries flaws inline, and each indexed change carries its own cost, so no separate
past-tense statement and no opening "good at" line survive.

### (settled) `design-it-twice-any-fork` — a protocol ref for any real fork, runnable without subagents

`refs/design-it-twice.md` held as the optional heavy path, invoked when a fork is worth arguing about:
a contract, a data model, a module split.
The protocol: frame the constraints, produce several candidate structures each under a different
constraint, compare on the depth sentence, recommend one and say what it gives up.
The constraint list is the portable part — minimise the contract, maximise flexibility for a known
future change, optimise the most common caller, isolate the volatile dependency.

No fixed number of candidates, and no requirement for parallel subagents: write the alternatives
yourself when nothing can be spawned, spawn them when something can.
The protocol's output stays in conversation unless the user agrees to a note under
`design-note-on-agreement`.
