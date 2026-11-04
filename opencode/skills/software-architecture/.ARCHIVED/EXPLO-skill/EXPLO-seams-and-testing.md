# seams-and-testing — exploration

Seam discipline and how testing follows from it: adapter counting, dependency categories,
the interface as test surface, and retiring tests when a seam lands.

## Findings

- Their rule: one adapter means a hypothetical seam, two adapters means a real one.
  Don't introduce a port unless two adapters are justified (typically production + test).
- Internal seams (private to an implementation, used by its own tests) are distinct from the
  external seam at the interface; internal ones must not leak into the interface.
- Four dependency categories, each mapping to a test strategy:
  in-process (merge and test directly), local-substitutable (run the stand-in),
  remote-but-owned (port + HTTP adapter, in-memory adapter in tests),
  true external (injected port + mock adapter).
- "The interface is the test surface" — callers and tests cross the same seam.
- "Replace, don't layer": once tests exist at the deepened interface, delete the old per-helper tests.
- Our draft's `seam-at-the-boundary` pattern says seams cost indirection and should be paid for where
  a test or second implementation exists — the same idea, stated more softly and without categories.

## Design crux

Our pattern tells you where to cut but not how to test across the cut, so it stops one step short of
being actionable.
Their dependency categories do the work, but assume ports-and-adapters vocabulary we do not have.

## Candidate directions

None live.

## Decisions

### (settled) `internal-seam-one-sentence` — no named internal-seam concept

The seam pattern carries one sentence: a substitution used only by a module's own tests stays private and
does not enter the contract.

No glossary term and no rule, because our modules are small enough that the distinction rarely changes a
decision.

## Decisions

### (settled) `two-adapter-rule-with-effect-exception` — one adapter is hypothetical, two are real

A seam is justified when two adapters exist: a real second implementation, or an effect already
substituted in tests.

Phrasing matters: the exception reads "an effect already substituted in tests", not "a test fake", so
the clock, filesystem, environment, and randomness qualify while "we might swap the database one day"
does not.
This replaces the draft's softer "pay for the seam where justified", which left the judgement to taste.

### (settled) `dependency-categories-reworked` — four categories, with a substitution category

The four categories, each with one line of test strategy, live inside `seam-at-the-boundary.md`:
- in-process — merge it and test directly.
- substituted — clock, filesystem, environment, subprocess, randomness: inject it and hand in a fixed
  version in tests.
- remote but owned — a real adapter in production, an in-memory one in tests.
- true external — inject the contract and use a mock adapter.

The second category is ours: the reference skill has no home for the clock, and its in-process category
("merge and test directly") would wrongly swallow an effect.
No ports-and-adapters naming appears unless a category needs it.

### (settled) `contract-is-test-surface-rule` — tests cross the contract, never the internals

Added to `## Rules`: callers and tests cross the same contract, so a test that reaches past it is
testing an implementation, and any refactor breaks it.

It is the general form of the `detect-plan-apply` payoff ("assert the plan, not the effects"), stated
once so it also covers modules with no seam in sight.

### (settled) `replace-dont-layer-rule` — retire the tests a new seam makes redundant

Added to `## Rules`: when a contract-level test lands, delete the tests it replaces rather than leaving
both layers.

Kept out of the seam pattern's pitfalls because the deletion happens later, during a test pass, when
that pattern is not open.

## Open threads

- Do the vocabulary's `effect` list and the new "substituted" category ever drift apart?
