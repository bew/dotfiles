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

- (active) **<candidate>** — <short gist>
- (deferred) **<candidate>** — <short gist>; expanded below

### <candidate>

<free-form expansion: rationale, tradeoffs, sub-variants — as long as needed>

## Decisions

- (settled) **<decision>** — <short gist>

### <decision>

<free-form expansion — as long as needed>

## Open threads

- <unresolved question>
```

The bullet list under `Candidate directions` / `Decisions` is the canonical index:
one bullet per item, status leading, short gist.
An item may be expanded into a `### <item>` subsection placed after the list —
the bullet stays, and the expansion may run to any length the item needs.
Only add an expansion when the user asks for it, or when a few rounds were spent
exploring that item and the detail is worth preserving.

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
- `rejected` — dropped; give the reason in the bullet gist (expand below if needed).

Decision status (topic `Decisions`):
- `settled` — current, agreed.
- `superseded` — replaced by a later decision.
- `reversed` — explicitly undone.

Never rename a topic file. In `dedicated` mode status lives only in the brief index;
in `adhoc` mode it lives only in the H1 tag.