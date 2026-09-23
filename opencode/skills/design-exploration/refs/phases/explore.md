# Phase:Explore — per-topic discussion loop

## Start or resume a topic

Pick `$topic` (kebab-case lowercase) for the current thread:
- If an `active` topic file already covers it, resume that file.
- If a `frozen`/`revived` topic file covers the same or an extended direction, revive it.
- If the direction is completely different, start a new topic file.

Apply the formats and index rules in <../artefacts.md>:
- New topic: append it to the brief index and write `$topicpath`.
- Revived topic: update its status in the brief index.

## The loop

Apply the `Interaction conventions` from `SKILL.md` in every round.
For each round:
- Fold every outcome into `$topicpath`: `Findings`, `Design crux`,
  `Candidate directions`, `Decisions`, `Open threads`.
- Move a direction's status as it evolves: `active` → `deferred` / `rejected`.
- Move a decision's status as it evolves: `settled` → `superseded` / `reversed`.

Don't pre-create empty sections — fill them as content lands.

## Conclude a topic

When the user signals a topic's design is settled:
- Mark the topic `frozen` in the brief index.
- Leave any unresolved items under `Open threads`.

Ready to move to `Phase:Wrap`, or explore another topic?