# Phase:Explore — per-topic discussion loop

## Recap before a topic switch

Emit the `SKILL.md` recap — *Recaps flag outstanding open threads* — inline before picking a new
`$topic`, unless no topic has been explored yet.
The user decides whether to resume a topic or carry on.

## Start or resume a topic

Pick `$topic` (kebab-case lowercase) for the current thread:
- If the direction only restates a settled decision owned by another topic, point at that decision
  by slug instead of opening, resuming, or reviving a topic, then add it to the current topic's
  `related-to:` line — appending with ` & ` when one is already there.
- If an `active` or `unsettled` topic file already covers it, resume that file and set it `active`.
- If a `frozen`/`revived` topic file covers the same or an extended direction, revive it.
- If the topic was left `unexplored`, start it: write its file and set it `active`.
- If the direction is completely different, start a new topic file.

Apply the formats and status rules in <../artefacts.md>.

In `dedicated` mode:
- New topic: append it to the brief index and write `$topicpath`.
- Revived topic: update its status in the brief index.
- `unsettled` topic: resume `$topicpath`; set its status back to `active` in the brief index.
- `unexplored` topic: write `$topicpath`; update its status in the brief index and drop its
  `(unexplored)` line from the parent's `Open threads`, if present.

In `adhoc` mode:
- New topic: write `$topicpath` with `## Motivation`; its H1 carries `[active]`.
- Revived topic: set the H1 tag to `[revived]`.
- `unsettled` topic: resume `$topicpath`; set the H1 tag to `[active]`.
- `unexplored` topic: write `$topicpath` with `## Motivation`; set its H1 to `[active]` and drop
  its line from the parent's `Open threads`.
- A new direction: ask the user to either add a sibling file here or upgrade to a
  dedicated dir — the upgrade returns to `Phase:Setup` in `dedicated` mode.

## The loop

Apply the `Interaction conventions` from `SKILL.md` in every round.
For each round:
- Fold every outcome into `$topicpath`: `Findings`, `Design crux`,
  `Candidate directions`, `Decisions`, `Rejected directions`, `Open threads`.
- Move a direction to `## Rejected directions` at the agent's call, dropping its marker; move it to
  `(deferred)` only when the user parks it.
- A decision that later changes is replaced in place, keeping its slug — never annotated
  `(superseded)` or `(reversed)`.
- A shape the agent assembled stays `(active)` under `Candidate directions` until the user
  answers the concrete proposal — see *Only the user settles a decision* in `SKILL.md`.
  Recording it under `Decisions` first is a failure, not a shortcut.

Don't pre-create empty sections — fill them as content lands.

## Conclude a topic

When the user signals a topic's design is settled:
- `dedicated`: mark the topic `frozen` in the brief index.
- `adhoc`: set the file's H1 tag to `[frozen]`.
- Leave any unresolved items under `Open threads`.

Freezing the last topic does not end the exploration.
Move to `Phase:Wrap` and ask its exit question; the user decides whether to exit.

Ready for `Phase:Wrap`? (say 'next' or similar to proceed)
