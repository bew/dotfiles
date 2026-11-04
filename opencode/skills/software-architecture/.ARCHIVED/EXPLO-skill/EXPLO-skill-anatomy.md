# skill-anatomy — exploration

How `SKILL.md` is laid out: which sections exist, in what order, and how each stays scannable.

## Findings

- The draft carries Goal, Scope, Design moves, Pattern index, Rules, Guidelines.
- `## Rules` grew to seven entries once the test-surface and retire-tests rules landed, which is where a
  constraint list starts reading as a checklist.
- Rules and guidelines split cleanly only if each rule is checkable: rule = holds always, guideline =
  judgement at design time.

## Design crux

Does the section list stay flat as it grows, or do the two long sections (vocabulary, rules) need their
own internal grouping to stay scannable without adding heading depth?

## Decisions

### (settled) `rules-grouped-three-frames` — seven rules, three italic frames

`## Rules` keeps all seven entries and groups them under three frames, mirroring the vocabulary's
frame style:
- *place the effects* → logic reads no effects.
- *own the values* → one owner per value; closed sets are named types; no implicit design decision.
- *land the change* → plan before apply; contract is the test surface; retire replaced tests.

All seven stay checkable, which is why the alternative that demoted "no implicit design decision" to a
preamble lost.

## Open threads

- Does `## Guidelines` survive as a separate section, or does it fold into the design moves?
- Section order once vocabulary and rules are grouped.
- Line budget for `SKILL.md` as a whole.
