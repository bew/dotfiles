# data-shape — exploration

What the `Decide the data shape` frame has to decide, and how much of it lives in the frame itself.

## Findings

- The frame is five lines: variation that arrives whole wants data rather than a flag threaded through
  call sites, plus pointers to `data-over-flags` and `explicit-decision-table`.
- Every line is about flags at call sites. Nothing on what a data object is, whether it can exist in an
  invalid state, the difference between a value and a thing with identity, or how a data model grows.
- `software-vocabulary` has no data nouns. Its terms are module, deep module, package, implementation,
  logic, orchestrator, contract, signature, seam, adapter, owner, local state, shared state, operation,
  command, lifecycle, workflow, side-effect. No value, record, identity, entity.
- The vocabulary claims it `defines its structural terms`, so adding data nouns is a second file to edit,
  and it reopens the drift question settled in `topic:shared-vocabulary`.
- `SKILL.md` is 149 lines; this frame can grow to twenty without pressing the budget. `## Vocabulary` is
  the tighter one.
- The user named three gaps: data objects, how to structure the data model incrementally, and the
  domain-driven vocabulary around them.
- `aggregate` would fight the rule `one owner per value`: an aggregate is a cluster of values owned
  through one boundary.
- The user's call on the vocabulary gap: a dedicated skill, not nouns inside this one.
  A domain-modelling skill first, inspired by `mattpocock/skills` `engineering/domain-modeling`
  (glossary, ADRs, challenging terms), then a data-model design skill.
  Both captured as tasks: `TASK-domain-modeling-skill.md`, `TASK-design-data-model-skill.md` under
  `opencode/skills/`.
- That split dissolves the vocabulary-ownership thread: the data nouns get a home outside a skill
  that claims structural terms only. It leaves the frame's own fate undecided.

## Design crux

Which data decisions actually change a design, and does that reasoning belong in the frame itself or in
an entry behind it?

## Candidate directions

- (deferred) **invariants and growth, no DDD nouns** — the frame teaches that a data object is valid or does
  not exist (the constructor refuses), that a value and a thing-with-identity age differently, that fields
  which travel together become one record, and that a model grows one `operation` at a time.
  *For*: cheapest of the four, and it sits on rules already present (`closed set is a named type`,
  `one owner per value`) instead of importing a second vocabulary.
  *Against*: it grants none of the domain language the user asked for, so "domain model" stays a phrase
  the skill never uses.
- (deferred) **DDD vocabulary imported** — `entity`, `value object`, `aggregate`, invariant boundary,
  ubiquitous language.
  *For*: names what practitioners already look for, and ubiquitous language pairs naturally with
  `Identify the load-bearing concepts`.
  *Against*: four or five new terms, one of them in open conflict with an existing rule, and the frame
  starts reading as a DDD primer rather than a design decision.
- (deferred) **hybrid** — growth and the value/identity split inline, `entity` and `aggregate` named once
  with a pointer to a ref that defines them.
  *For*: answers "what is this data object" without a primer, and keeps the vocabulary to structural nouns.
  *Against*: ambiguous ownership — if the vocabulary does not define `entity`, the design skill does, which
  is the arrangement the head pointer just stopped claiming.
- (deferred) **frame stays short, new `refs/patterns/data-model-growth.md`** — the entry carries validity,
  identity, and incremental growth; the frame keeps one sentence and a pointer.
  *For*: matches every other frame's shape (three to five lines plus a ref) and grows no vocabulary.
  *Against*: the index is a list of situations, and a data model is not one; an entry that every design
  hits would need an index row it does not earn.

## Decisions

### (settled) `frame-kept-thin-gap-deferred` — the frame keeps its place and names what it does not decide

related-to: `topic:output-structure`

The frame stays where it is and keeps deciding variation that arrives whole.
It gains one line naming what it does not decide: what makes a thing valid, what identifies it, and
what is derived rather than held.
Those are decided ad hoc for the run, and the choice behind them is stated in the report — the
`Data` bullet carries the same note, so neither end can stay silent about the gap.
Model growth stays out of both lines: it remains a candidate above, not something this pair decides.

The proper homes are `task:domain-modeling-skill` and `task:design-data-model-skill`.
The frame is revisited once a data-model skill exists; until then the candidates above are
read by that skill, not by this one.

## Open threads

- Does `identity` earn a term in `software-vocabulary` — deferred, hangs off
  `task:design-data-model-skill`.
