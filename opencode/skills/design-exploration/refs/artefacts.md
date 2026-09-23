# Exploration Artefacts

Exploration starts in a mode resolved at `Phase:Setup`.

## Modes

- `dedicated` — a dedicated dir holding a brief hub plus one `EXPLORATION-<topic>.md`
  per topic; used when a caller supplies a dir or several topics are expected.
- `adhoc` — no brief; `EXPLORATION-<topic>.md` files live in the working dir.

## `EXPLORATION-BRIEF.md` (`dedicated` only)

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

In `adhoc` mode the same sections apply, with these changes: a `## Motivation`
section leads each file, and the file's status lives in the H1 tag:
```md
# <topic> — [active]

## Motivation

<context, problem, scope — derived from the user's instructions>

## Findings

...
```

## Status vocabularies

Topic status:
- `dedicated` — recorded in the brief index as `(<status>)`.
- `adhoc` — recorded in the file's H1 as `# <topic> — [<status>]`.
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

Never rename a topic file. In `dedicated` mode status lives only in the brief index;
in `adhoc` mode it lives only in the H1 tag.