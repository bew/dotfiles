# Research

## Goal

Build a cited fact base and a coverage oracle before any README prose exists.
Research answers reader questions; it does not summarise the source.

## Source order

Read in this order, because purpose and invariants live outside the package:
- Call sites in consumers: how the package is constructed, configured, and called.
- Tests: the common path and the required initialisation.
- Package module docs and public type definitions.
- Manifest and features.

Never infer a caller convention from the package alone.
A fact that only a call site establishes is still a `must` fact.

For *Review* and *Update*, research the source before re-reading the current README.
The existing text must not define the question set.

## Question set

Answer these, in order, with at least one `file:line` per answer:
- Orientation: what is the package, and which three reader tasks bring someone here?
- Boundary: what does it own, and which sibling or OS owns the rest?
- Consumers: who calls it, in what role, and through which entry points?
- Invariants: which values, orderings, or lifecycle rules are enforced by callers rather than by the package?
- Objects: which three to five relationships among types explain the design?
- Failure: what is rejected, with which error type, and what happens to partial input?
- Usage: what is the smallest correct call sequence, taken from a test or a consumer?
- Evolution: which compatibility rules must someone changing this package follow?

Stop at the cap.
Three reader tasks and five relationships are ceilings, not targets.
More is an inventory, not an overview.

## Output

Return a table, not prose:

| Fact | Answers | Evidence | Rank |

- `Fact`: one atomic statement, no hedging.
- `Answers`: the question above it answers.
- `Evidence`: `file:line`, and a second locator when the fact spans a boundary.
- `Rank`: `must`, `optional`, or `omit`.

Rank `must` when a reader cannot use or change the package correctly without the fact.
Rank `optional` when it aids understanding but omits cleanly.
Rank `omit` when it is true but incidental: instrumentation, private helpers, or an exhaustive type list.

Do not name a private symbol unless its behaviour is visible outside the package.
Do not quote a constant's value.

## Tiering

- Small package (three or fewer source files): one subagent runs the whole set.
- Larger package: two or three parallel subagents.
  Split by question, not by file: purpose and consumers; mechanism and invariants; failure and usage.
- A cross-crate invariant needs a consumer locator even for a small package.

## Handoff

Return the table and a short list of unresolved questions.
The main agent turns it into the brief in *Step:Brief*.
Research prose never enters the README.
