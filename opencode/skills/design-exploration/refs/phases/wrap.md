# Phase:Wrap — freeze settled topics; ask the exit question

## Never finish automatically

`Phase:Wrap` never ends the exploration on its own.
Only an explicit answer to the exit question below ends it.
A frozen topic, a covered topic, a lull in the discussion, or the agent's own judgement that
everything is settled are not exit signals.

## Freeze

Confirm every topic carries a status (`active`/`frozen`/`revived`/`unsettled`/`unexplored`),
recorded per the mode in <../artefacts.md>.
`active` and `revived` stay provisional until the exit answer re-records them.
Freeze any topic the user declares settled; note genuinely unresolved `Open threads`.

## Exit question

Emit, inline, before the `question` tool call:

- **Covered topics** — each topic with its status, and where its record lives: its file, or for an
  `unexplored` topic the brief-index row or the parent's `(unexplored)` line.
- **Recap** — the `SKILL.md` recap (*Recaps flag outstanding open threads*).
- **Potential remaining topics** — each topic still holding `(active)` directions or deferred
  candidates.

Live threads and undecided proposals are unfinished work, not an unexplored direction: list them
under the recap, never as a remaining topic.
A topic holding only those still gets its own option below, so the remaining-topic list and the
option set differ on purpose.

Do not skip the remaining topics because the list feels complete:
this list is the agent's view, not a verdict.
Exiting with a direction still on the table leaves it open and out of drafting: state that
explicitly when the recap holds one.

Then use the `question` tool, in this order:

- first option: the exit option (see below)
- one option per topic holding open threads, remaining directions, or an undecided proposal, named
  after that topic

A topic holding more than one gets one option; its description names each.
Ask a single-select question: `multiple` is never set, since one answer either ends the phase
or continues it.
Give every option a one-line `description`.

The exit option label differs based on `$fordraft`:
- `$fordraft=true` — `󰷈 Switch to Draft`
- `$fordraft=false` — ` Stop exploring`
The leading glyph is decoration; the label starts with `Switch to Draft` / `Stop exploring`.

With no such topic, the option is that label exactly.
Do not skip the question when the list looks empty: the user may still name a new topic.

With such a topic, the exit option is one of:
- `󰷈 Switch to Draft (ends exploration; remaining topics and open threads left open)`
- ` Stop exploring (remaining topics and open threads left open)`

Picking any topic option returns to `Phase:Explore` on that topic; `Phase:Wrap` does not end.
A free-text answer naming a new topic does the same.
On the exit option, mark a topic that never got a file of its own `unexplored` — its brief-index
row in `dedicated`, its parent's `(unexplored)` line in `adhoc`.
Add the row or the line when the topic has none yet; with no parent topic, the line goes in the
`Open threads` of the topic just discussed.
Record an opened topic that was not settled as `unsettled`, whether it was `active` or `revived`;
one already `frozen` stays `frozen`.
A re-entrant session resumes an `unsettled` topic like an `active` one.
Open threads stay in their topic files untouched — never mark one resolved on exit.
Only that answer ends the exploration, with or without remaining topics; there is no 'say next'
gate in this phase.
A dismissed or ignored question is not an answer — re-ask before anything leaves `Phase:Wrap`.

The exploration files remain for a later draft or a re-entrant session.
