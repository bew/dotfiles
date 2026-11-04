# pattern-catalogue — exploration

Which of the six drafted patterns survive the inspiration pass, whether a seventh (deep modules) is
added, and what an entry looks like.

## Findings

- Drafted patterns: `detect-plan-apply`, `pure-core-effects-at-edge`, `explicit-state-machine`,
  `data-over-flags`, `single-source-of-truth`, `seam-at-the-boundary`.
  Each: Problem / Shape / Payoff / Pitfalls, Python examples marked as pseudocode.
- Their skill has no pattern catalogue; depth is the only pattern-shaped idea, plus the deletion test.
  Everything else is vocabulary and seam discipline.
- Overlap found: `seam-at-the-boundary`, their "designing for testability" list, and
  `detect-plan-apply`'s testability payoff all argue the same point from different angles.
- `single-source-of-truth` and `data-over-flags` have no counterpart in their skill; they come from
  our own reading and survive on their own merit.
- A possible seventh: **deep modules** — small interface, larger implementation, judged by the
  deletion test. It is the governing shape the other six sit inside.

## Design crux

Do the six patterns stay peers, or does one of them (deep modules) become the frame the rest hang
from?
A frame makes the catalogue coherent; peers keep each entry independently useful.

## Candidate directions

- (deferred) **Count and fate of the seam entry** — six as drafted, five merged into one
  `effects-behind-a-seam` entry, or five with the dependency categories demoted into the depth
  frame and the seam entry dropped.
  Deferred because the frame decision changed the seam entry's content and the call needs a pass
  over the actual entry files, not the topic description.

## Decisions

### (settled) `depth-frame-above-index` — depth is a frame, not a seventh entry

Deep modules sits as a short section above the pattern index, read once before any entry.
The six patterns stay flat peer rows and are not rewritten to argue depth.

Why: three of the six (`explicit-state-machine`, `data-over-flags`, `single-source-of-truth`)
are about representation, not about what a module hides.
Forcing them into a depth argument needs a second axis and a two-axis table, more structure than
the skill carries.

The frame owns the material that would otherwise repeat across entries: deletion test run both
ways (complexity vanishes → pass-through; reappears across N callers → earned its keep),
small contract over large implementation, and the two-adapter rule as a depth argument
(a seam with one adapter demands knowledge and delivers no swappable behaviour).
This is why the frame must sit above the index: a frame read after the entries is decoration.

Accepted cost: the entries lose their testability paragraphs to the frame, so an entry read in
isolation no longer justifies itself.

### (settled) `entry-hybrid-with-gain` — recognition heading, deduped shape, explicit gain

Entry format, in this order:

- `### When it applies` — one sentence naming the situation that makes the pattern relevant,
  replacing the former `Problem` heading. The index rows are worded to match.
- `### Shape` — prose first, carrying only what the code cannot: why the split is where it is,
  what the record must not hold, which piece owns the effects.
  A `pseudocode` fence follows with the contract.
  Nothing the signature already states is repeated in prose.
- `**Gain**:` — one bolded line at the end of `Shape`, stating what the shape buys.
  Kept rather than dropped because an entry makes no promise otherwise.
- `### Pitfalls` — bullets, one discrete failure each, not prose.

Why the hybrid: separating `Shape` from `Shape in code` invites the two to drift, and the dedupe
rule only holds when the code lives inside the section whose prose it complements.
`Payoff` as a section restated `Shape` in benefit language; one bolded line does the same job at
a fraction of the cost.

Accepted cost: renaming `Problem` to `When it applies` moves each entry from complaint framing to
situation framing, so the index no longer reads as a list of problems.

### (settled) `index-table-with-lead-in` — table of triggers, opened by one warning line

The pattern index is a two-column table: pattern name, and a `read when` trigger condition.
One sentence sits above it saying the catalogue is a set of situations, not a checklist — pick the
row that matches, do not walk all rows.

Why: the row is a trigger, not an abstract; it is the only thing always read, and the entry is
opened only when a row fires.
The lead-in costs one line and prevents the catalogue being applied as a checklist.

Wording rule: the row's trigger is written first and the entry's `### When it applies` heading is
derived from it, never the reverse — the row is the version under line pressure, so it must be the
one written deliberately.

Accepted cost: table cells force the trigger into one line, so a second clause or a contrast
("not for single-shot writes") cannot be carried in the row.

### (settled) `no-reference-links` — entries carry no pointers to real code

Pattern entries contain no "seen in" line and no path into this repo or any other, even where a
working implementation exists.

Why: a path is the fastest thing in an entry to rot, and a silent lie in a design reference is
worse than an absent example.
The examples in each entry are pseudocode on purpose, so a link to a real script would also invite
reading the sample as a language guide rather than as a shape.

Consequence recorded rather than hidden: `detect-plan-apply` loses its strongest evidence, and the
skill no longer records that the pattern came from `opencode/skills/write-spec/scripts/manage-spec`.
That provenance belongs in the task record that started the work, not in the entry.

### (settled) `no-entry-length-cap` — entries end when the content ends

The skill states no length limit for a pattern entry, neither a line count nor a screen.

Why: the six entries already fit comfortably after `entry-hybrid-with-gain` merged `Shape` and
`Shape in code` and reduced `Payoff` to one line, so a cap would only bind future edits.
A numeric cap invites cutting the pitfall that matters to fit the number.

Accepted cost: nothing prevents an entry growing one addition at a time, and that drift is
invisible while it happens.
Placement alternative rejected for the same reason the cap was: a lead-in line saying "keep entries
short" is not checkable and adds words to a section that should stay lean.
