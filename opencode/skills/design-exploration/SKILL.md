---
name: design-exploration
description: |
  Methodology for maturing a design before a spec, plugin, or other artefact draft exists.

  Load when:
  - user asks to explore, compare candidate designs, or mature a design for a system / topic
  - an important design is genuinely uncertain (competing models, an undefined central concept)
    and writing a spec or draft would be premature
  - an existing design forks and deeper exploration of a topic is wanted
  - "write explo …"
  - editing an `EXPLO-BRIEF.md` or `EXPLO-<topic>.md` file
metadata:
  maintainers: [bew]
---

# Skill: design-exploration

## Goal

Mature an immature design through an open-ended, proposal-first discussion loop, recording
findings, candidate directions, settled decisions, and open threads in topic-scoped
exploration files so a spec or other artefact draft can later be written from settled ground.

## Phases

1. `Phase:Setup` — resolve identity, mode & path; seed files
2. `Phase:Explore` — per-topic discussion loop; write topic exploration files
3. `Phase:Wrap` — freeze settled topics; ask the exit question

**Vars used throughout**: (output them in context once known!)
- `$mode` — `adhoc` (no brief; topic files in the working dir) or `dedicated` (dir + brief).
- `$explodir` — directory for the exploration files (`adhoc`: the cwd).
- `$briefpath` — `$explodir/EXPLO-BRIEF.md`; `dedicated` mode only.
- `$topic` — current topic label, kebab-case lowercase.
- `$topicpath` — `$explodir/EXPLO-$topic.md`.
- `$title` — the design's human-readable name.
- `$slug` — the design's kebab-case slug.
- `$fordraft`:
  * `true` when the exploration is for a draft (spec, plugin, or other artefact) that will be
    created/updated later;
  * `false` when the exploration runs standalone.
  * when `true` and the caller supplies a dir (artefact dir or exploration dir),
    `Phase:Setup` pins `$mode` to `dedicated` and `$explodir` to that dir, without asking.

## Interaction conventions

Apply in every phase.

- **Proposal-first.** Draft candidate ideas and rough shapes by default; state assumptions.
- Emit questions **inline** in the reply before reaching for the `question` tool.
- Use the `question` tool at genuine mutually-exclusive forks, and for the `Phase:Wrap`
  exit question.
  Keep it dismissible — the user may ignore it and answer in their own terms,
  except at `Phase:Wrap`, where silence is not an answer.
- Don't pre-create empty sections — fill them as content lands.
- Do not mandate `incremental-write` — its skeleton-first ceremony fights the fluid loop.
- **Only the user settles a decision.** Any shape the agent assembled from the user's words —
  a merged option, an inferred hybrid, a multi-part combination — is a proposal, not a decision.
  Spell the concrete shape out in full, then wait for the user's explicit answer to that shape.
  A user question ("could we do 2+3?", "what about a hybrid?") opens a candidate; it never
  settles one. Until answered, it stays `(active)` under `Candidate directions`.
  One user answer approves one exact shape — never extended to a variant nobody answered.
  Record the decision with the same parts and wording as the approved proposal;
  a reworded or widened entry needs its own answer.
- Record approved decisions as they land; keep `Open threads` current.
- **A decision is a slugged section.** Record it as ``### (settled) `<slug>` — <title>`` under
  `## Decisions` of its topic file; the slug is its identity and stays for the record's whole life.
  Slugs are kebab-case and unique across `$explodir`.
  Point at a record by slug — bare for a decision, `topic:<slug>` for a topic file — never by
  quoting a title, since a reworded title would leave a dead pointer that still reads plausibly.
  Live directions stay one-line bullets; a rejected one moves to `## Rejected directions` without a
  marker.
- **Mirror a coupling.** `coupled-with:` claims two records move together, so both records carry the
  edge; `related-to:` is one-way navigation among exploration records and topics.
- **Recaps flag outstanding open threads.** Every recap — before a topic switch, and around the
  `Phase:Wrap` exit question — shows the topic just discussed with its status, its remaining
  `Open threads`, and its directions still on the table; then every other topic that still holds
  `Open threads`, with its thread lines.
  Reporting only that topic reads as if nothing else is unfinished.
  Threads flag, never block: a switch, a freeze, and the exit answer all stay available.
- **Never echo the file.** After writing or updating any exploration file (`$topicpath`
  or `$briefpath`), do not reproduce its content inline. Reply with a short overview
  (what the file now holds, where it lives) and only the actionable items — open forks,
  decisions awaiting the user's call.
  Exception: the `Phase:Wrap` covered-topic list, which is the status index by design, and the
  open-thread lines the recap rule above requires.

## 1. `Phase:Setup` — resolve identity, mode & path; seed files

When entering `Phase:Setup`: read <./refs/phases/setup.md> for full instructions.

## 2. `Phase:Explore` — per-topic discussion loop

When entering `Phase:Explore`: read <./refs/phases/explore.md> for full instructions.

## 3. `Phase:Wrap` — freeze settled topics; ask the exit question

When entering `Phase:Wrap`: read <./refs/phases/wrap.md> for full instructions.
