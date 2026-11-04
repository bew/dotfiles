# vocabulary-and-depth — exploration

Where the glossary lives, and whether one evaluative metric (depth) earns a place in the skill.
Which nouns go in the glossary is settled in `topic:vocabulary-nouns`.

## Findings

- Their `SKILL.md` keeps the glossary inline and short, with the deep-vs-shallow diagrams right after.
- Depth is defined there as leverage at the interface, deliberately rejecting Ousterhout's
  implementation-lines / interface-lines ratio.
- Depth is not measurable, and it rewards hiding behaviour — which is wrong when callers genuinely
  need the knob that was hidden.
- Our skill already judges by pattern fit plus per-pattern pitfalls, so an abstract metric can quietly
  override the patterns.
- The deletion test needs no setup and produces a yes/no answer, unlike depth.

## Design crux

Is a judging metric useful at all in a skill whose evaluation surface is already a catalogue of
patterns with named pitfalls?
A metric is worth its lines only if it changes a decision the patterns leave open — comparing two
candidate structures, or critiquing an existing one.

## Candidate directions

- (deferred) **Deletion test as a rule, not a pattern** — delete the module mentally: complexity vanishes
  → pass-through, complexity reappears across N callers → it earned its keep.
  User deferred the placement question.
- (active) **Group the vocabulary into logical groups** — proposed shape: six groups inside
  `## Vocabulary`, each with its terms and their `_Avoid_:` lines. Question raised by the user:
  does grouping also mean fewer ref files?

## Decisions

### (settled) `glossary-inline-in-skill` — the vocabulary sits inline in `SKILL.md`

Definitions live in a `## Vocabulary` section of `SKILL.md`, always loaded, so the wording is available
before any pattern ref is read.
`refs/vocabulary.md` would load on demand and cost less per run, but a pattern ref can be opened
without it — exactly when the words matter.

### (settled) `depth-preference-in-move` — the depth tie-breaker lives in a design move

When two structures both satisfy the patterns, prefer the one with the smaller contract for the same
behaviour; a thin adapter is not shallow, because the behaviour sits behind it.

It sits in the move that compares candidate structures, not in `## Rules`, because a tie-breaker is
judgement and `## Rules` holds only invariants that are always true.
Accepted cost: a plain critique pass reads the moves but not necessarily this sentence, so the
preference is not enforced there.

### (settled) `vocabulary-grouped-by-frames` — six blocks, one italic frame each

Terms are grouped by the question they answer, and each block opens with an italic frame line naming
that question, with no heading level and no other marker.

The six frames: what code is this, what role does it play, where can it be swapped, who decides each
value, what work runs, what touches the outside world.

Accepted cost: five extra lines over a flat list.

### (settled) `rejected-framings-in-vocabulary` — the block sits inside `## Vocabulary`

The three corrections live with the terms they correct, so a reader meets "depth is not a line ratio"
next to the definition of depth rather than elsewhere in the file.
Cost: the section carries a preamble before its first definition.

### (settled) `no-depth-diagrams` — no deep-vs-shallow ASCII diagrams

The diagrams presuppose a layered architecture, which the skill does not assume, and carry no decision
content a one-line definition cannot.
Depth stays prose.

## Open threads

- How many lines can `## Vocabulary` take before it crowds out the moves and the pattern index?
- Does grouping the terms into six sections pay for its header lines?
