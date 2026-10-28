# Phase:Setup — resolve identity, mode & path; seed files

## Resolve identity

Derive:
- `$title` — the design's human-readable name.
- `$slug` — the design's kebab-case slug.
- `$fordraft` — `true` when the exploration feeds a draft (spec, plugin, or other artefact),
  `false` when nothing says so.

Take `$title` and `$slug` from context if present; otherwise ask.

Default `$fordraft` to `false`; only a caller that will turn the exploration into a draft sets
it to `true`.

## Resolve mode & path

Read <../artefacts.md> for the mode definitions.

**Caller supplied the dir** — `$fordraft=true` and the caller passed the dir to use: the
artefact dir (spec, plugin, skill, agent) or an exploration dir:
- `$mode` = `dedicated`.
- `$explodir` = the supplied dir.
  In an artefact dir, the brief and topic files sit next to the artefact files
  (`EXPLO-BRIEF.md` beside `SPEC.md`).
- Adopt both without asking; state `$mode` and `$explodir` in the reply.
  No confirm question in this branch; Seed creates the dir when absent.

**Otherwise** — standalone exploration, or the artefact is a single file (command `.md`,
snippet): pick the candidate `$mode`:
- `dedicated` — the invoking context supplies an exploration dir, or several topics are expected.
- `adhoc` — no supplied dir and one topic expected; files go in the working dir, with no brief.

For a single-file artefact with no supplied dir, the candidate is `dedicated`
(`EXPLO-$slug` beside the artefact); the confirm question also offers `adhoc`.

Pick the candidate path:
- `dedicated` — the supplied dir; next to a single-file artefact, `EXPLO-$slug` in that file's
  parent dir; else `EXPLO-$slug`.
- `adhoc` — the current working dir.

Confirm mode and path with the user in one question before creating anything.
On an `adhoc` upgrade the mode is already `dedicated` — confirm only the path.
Set `$explodir` to the confirmed path.

In either branch, `$briefpath` = `$explodir/EXPLO-BRIEF.md` (`dedicated` only).

## Seed

In `dedicated` mode:
- If `$briefpath` exists: read it, refresh `Motivation` if the instructions changed,
  keep the existing topic index.
- Otherwise: on an `adhoc` upgrade, first move the existing topic files into `$explodir`,
  naming each individually (an `EXPLO-<topic>.md` file) so a directory of the same prefix is
  never swept in.
  Then write `$briefpath` with an empty topic list, distilling the user's instructions into
  `Motivation` (context, problem, scope, out-of-scope), creating `$explodir` when it does not
  exist yet.
  Then index every `EXPLO-<topic>.md` present in `$explodir`: add it to the brief index with
  the status from its H1 tag, rewrite the H1 to the `dedicated` form
  (`# <topic> — exploration`), and convert its `## Motivation` section into the leading
  description paragraph (drop the section).
  This covers both an `adhoc` upgrade and a dir adopted in the first branch.

In `adhoc` mode: nothing is written yet — `Phase:Explore` creates `$topicpath`
with its `## Motivation`.

Ready to move to `Phase:Explore`? (say 'next' or similar to proceed)
