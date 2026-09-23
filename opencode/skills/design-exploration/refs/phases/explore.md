# Phase:Explore — per-topic discussion loop

## Start or resume a topic

Pick `$topic` (kebab-case lowercase) for the current thread:
- If an `active` topic file already covers it, resume that file.
- If a `frozen`/`revived` topic file covers the same or an extended direction, revive it.
- If the direction is completely different, start a new topic file.

Apply the formats and status rules in <../artefacts.md>.

In `dedicated` mode:
- New topic: append it to the brief index and write `$topicpath`.
- Revived topic: update its status in the brief index.

In `adhoc` mode:
- New topic: write `$topicpath` with `## Motivation`; its H1 carries `[active]`.
- Revived topic: set the H1 tag to `[revived]`.
- A new direction: ask the user to either add a sibling file here or upgrade to a
  dedicated dir — the upgrade returns to `Phase:Setup` in `dedicated` mode.

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
- `dedicated`: mark the topic `frozen` in the brief index.
- `adhoc`: set the file's H1 tag to `[frozen]`.
- Leave any unresolved items under `Open threads`.

Ready to move to `Phase:Wrap`, or explore another topic?