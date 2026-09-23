# Phase:Setup — resolve identity, mode & path; seed files

## Resolve identity

Derive:
- `$name` — the design's human-readable name.
- `$slug` — the design's kebab-case slug.

Take both from context if present; otherwise ask.

## Resolve mode & path

Read <../artefacts.md> for the mode definitions.

Pick the candidate `$mode`:
- `dedicated` — the invoking context supplies an exploration dir, or several topics are expected.
- `adhoc` — no supplied dir and one topic expected; files go in the working dir, with no brief.

Pick the candidate path:
- `dedicated` — the supplied dir, else `_WIP_EXPLORATIONS/$slug`.
- `adhoc` — the current working dir.

Confirm mode and path with the user in one question before creating anything.
On an `adhoc` upgrade the mode is already `dedicated` — confirm only the path.
Then set:
- `$explodir` — the confirmed path.
- `$briefpath` — `$explodir/EXPLORATION-BRIEF.md` (`dedicated` only).

## Seed

In `dedicated` mode:
- If `$briefpath` exists: read it, refresh `Motivation` if the instructions changed,
  keep the existing topic index.
- Otherwise: distill the user's instructions into `Motivation`
  (context, problem, scope, out-of-scope), and write `$briefpath` with an empty topic list.
- On an `adhoc` upgrade, also: move the existing `EXPLORATION-*.md` files into `$explodir`,
  add each to the brief index with the status from its H1 tag, and rewrite the H1
  to the `dedicated` form (`# <topic> — exploration`).

In `adhoc` mode: nothing is written yet — `Phase:Explore` creates `$topicpath`
with its `## Motivation`.

Ready to move to `Phase:Explore`? (say 'next' or similar to proceed)