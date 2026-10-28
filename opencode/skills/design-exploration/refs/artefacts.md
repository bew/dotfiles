# Exploration Artefacts

Exploration starts in a mode resolved at `Phase:Setup`.

## Modes

- `dedicated` — a dedicated dir holding a brief hub plus one `EXPLO-<topic>.md`
  per topic; used when a caller supplies a dir or several topics are expected.
- `adhoc` — no brief; `EXPLO-<topic>.md` files live in the working dir.

## `EXPLO-BRIEF.md` (`dedicated` only)

```md
# <$title> — exploration brief

## Motivation

<context, problem, scope, out-of-scope — derived from the user's instructions>

## Topics

- (active) `<topic>` — <short description>
```

Update `Motivation` as the brief evolves; keep the topic index current.
The index is the single source of truth for each topic's status.
Append new topics; never reorder the list. Update a topic's status in place.
Each topic's file is `EXPLO-<topic>.md`; a topic left `unexplored` has none.

## `EXPLO-<topic>.md`

```md
# <topic> — exploration

<a few lines stating what this topic is about>

## Findings

- <observation, fact, or constraint discovered>

## Design crux

<the central tension or question this topic must resolve>

## Candidate directions

- (active) **<candidate>** — <short gist>
- (deferred) **<candidate>** — <short gist>

## Decisions

### (settled) `<slug>` — <title>

related-to: `<slug>` & `topic:<slug>`
coupled-with: `<slug>`

<free-form expansion — as long as needed>

#### Example

<example of the decided shape>

## Rejected directions

- **<candidate>** — <why it lost>

## Open threads

- <unresolved question>
```

Keep every thread line to a single bullet line, with no nested bullets: a recap copies the thread
lines verbatim.

`Open threads` also carries a structural proposal the user has not decided yet — a split or a
rename — so a recap shows it as pending work rather than losing it.
Mark such a line with `(split)` or `(rename)`:
```md
- (split) `<new-topic>` — <which decisions belong apart>
- (rename) `<old-topic>` → `<new-topic>` — <why>
```

The line sits in the file of the topic being changed, so a `(split)` line names the topic to carve
out and the decisions it takes, by slug.
A topic with no file of its own takes its proposal line in the parent's `Open threads`, beside its
`(unexplored)` line.

Every topic file opens with a short description under the H1 — a few lines stating what the
topic is about, so the file reads on its own without the brief.
In `dedicated` mode this is a leading paragraph; in `adhoc` mode `## Motivation` already fills
that role.

Live directions and rejections stay one-line bullets:
`- (active) **<candidate>** — <gist>` while on the table, and
`- **<candidate>** — <why it lost>` once dropped.
An undecided direction costs one line; a decided one earns a section, because its prose and
examples are what a later draft reads.

A settled decision is a section headed ``### (settled) `<slug>` — <title>``.
The slug is the record's identity and the title is what a scanning reader sees; both sit on one
line, so reading the `## Decisions` headings answers "what did we settle".

Decisions live in the topic file that owns them.
There is no decision hub and no separate `EXPLO-DECISIONS-<topic>.md`.
The containing topic is the owner, so no `owner:` field exists; a reference that matters names the
file.

Slugs are kebab-case and unique across the whole exploration directory, the same invariant the spec
puts on item slugs.
A duplicate fails the check round rather than resolving to whichever record came first.

Never change a slug to describe a new shape.
A review pass replaces the record in place: keep the slug, rewrite the heading title and the body,
and leave every pointer resolving.

Reference lines sit directly under the record heading, and under a topic's leading description.
`related-to:` names an exploration record or topic this one leans on; `coupled-with:` names one that
must change with it, so editing either alone leaves the corpus inconsistent.
A decision record may carry both lines; a topic carries at most one of each.
Name more than one target with ` & `, as in ``related-to: `foo` & `bar` & `topic:baz` ``.
A bare slug names a decision; `topic:<slug>` names a topic file, because a topic and a decision can
share a slug.
`related-to:` holds exploration targets only — a section of a downstream artefact is named in
prose, not referenced.
`coupled-with:` is mirrored: both records carry the edge, so neither side moves alone.

When a duplicate record goes, its `related-to:` targets are re-pointed at the surviving record.
A `coupled-with:` edge is re-attached instead, because a pairing is a claim and survives the
deletion.

Examples live under the decision they illustrate, as a `#### Example` block.
A topic-level `## Examples` section does not exist: an example belongs to the decision it shows.

## Topic ownership and splits

Each decision has one owner: the topic that owns the behaviour it describes.
That topic holds the record; every other mention is a pointer.
A decision stated twice keeps the topic that owns the behaviour, not the one that merely mentions
it, so a pointer stays a pointer, never a second copy.

An overlap is not grounds for a merge.
Two decisions that answer different questions keep their own sections even once they share a file.

When one topic's decisions start answering different questions, propose a split; never split on your
own.
Record the proposal as a `(split)` line under `Open threads`.
A rename is proposed the same way, as a `(rename)` line.
Once the user approves a rename, rename the file to `EXPLO-<new-topic>.md`, rewrite the H1, update
its brief-index row in place, and update every `topic:<slug>` reference in that same step — a rename
with stale references leaves a broken corpus.
In `adhoc` the H1 also carries the topic's status, so it is rewritten in the same move.
Once the user approves a split, write the new topic file with its leading description, add its
brief-index row as `active` in `dedicated` mode or its H1 `[active]` tag in `adhoc`, move the
decisions it owns, and repoint the `topic:<slug>` references that followed a moved decision.
Either approval drops its proposal line from `Open threads`, leaving no stale proposal behind.
A declined proposal moves to `## Rejected directions` as a plain bullet, carrying its reason.
After a split, narrow the source topic's row description and leading description to what it still
owns, so it no longer claims the moved decisions.

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
- `active` — currently being explored; a topic that has never been frozen.
- `frozen` — settled; no further exploration expected.
- `revived` — currently being explored after a freeze; kept distinct from `active` so a resumed
  topic still shows it was settled once.
- `unsettled` — not settled at exit: opened but never settled, or reopened and left open.
  Resumable: a re-entrant session opens it like an `active` topic.
- `unexplored` — known, but never opened; the exploration ended before reaching it.
  Not a user decision — nobody weighed it.

Direction markers (topic `Candidate directions` / `Rejected directions`):
- `(active)` — still on the table; being pursued, including a concrete proposal the user has
  not answered yet.
- `(deferred)` — set aside by the user; parked for later, with no answer pending.
- rejections carry no marker: a bullet under `## Rejected directions` is dropped, and its gist
  gives the reason.

Decision marker (topic `Decisions`):
- `(settled)` — current, agreed by the user on that exact shape; never recorded from a
  proposal the user has not answered (see `SKILL.md` — *Only the user settles a decision*).

That is the whole decision vocabulary.
`superseded` and `reversed` are not markers: a review pass replaces the record in place and the
slug survives, so a pointer never has to follow a status word.

Never rename a topic file without the user's approval; the mechanics live in
`## Topic ownership and splits`.
A topic known only from a parent's `(unexplored)` line is renamed in that line, plus its
brief-index row when `dedicated`.
In `dedicated` mode status lives only in the brief index; in `adhoc` mode it lives in the H1 tag,
or in the parent's `(unexplored)` line for a topic with no file.
In `dedicated` mode that line is a mention, never a second status record.
A topic that never got a file of its own is `unexplored`; in `adhoc` mode its only record is a
line in the parent topic's `## Open threads`:
```md
- (unexplored) `<topic>` — <why it was not opened>
```
