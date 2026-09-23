# Exploration Artefacts

The explorations dir holds a hub brief and one file per topic.

## `EXPLORATION-BRIEF.md`

```md
# <$name> — exploration brief

## Motivation

<context, problem, scope, out-of-scope — derived from the user's instructions>

## Topics

- (active) `<topic>` — <short description>
```

Update `Motivation` as the brief evolves; keep the topic index current.
The index is the single source of truth for each topic's status.
Append new topics; never reorder the list. Update a topic's status in place.
Each topic's file is `EXPLORATION-<topic>.md`.

## `EXPLORATION-<topic>.md`

```md
# <topic> — exploration

## Findings

- <observation, fact, or constraint discovered>

## Design crux

<the central tension or question this topic must resolve>

## Candidate directions

- **<candidate>** — <one-line sketch>. _(active)_

## Decisions

- **<decision>** — <what and why>. _(settled)_

## Open threads

- <unresolved question>
```

## Status vocabularies

Topic status (recorded in the brief index only, as `(<status>)`):
- `active` — currently being explored.
- `frozen` — settled; no further exploration expected.
- `revived` — previously frozen, reopened for more exploration.

Candidate direction status (topic `Candidate directions`):
- `active` — still on the table; being pursued.
- `deferred` — weighed but no verdict yet; parked for later.
- `rejected` — dropped; append a one-line reason.

Decision status (topic `Decisions`):
- `settled` — current, agreed.
- `superseded` — replaced by a later decision.
- `reversed` — explicitly undone.

Never rename a topic file or add an in-file freeze marker; status lives in the brief index only.