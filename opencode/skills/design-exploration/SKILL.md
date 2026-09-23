---
name: design-exploration
description: |
  Methodology for maturing a design before a spec exists.

  Load when:
  - user asks to explore, compare candidate designs, or mature a design for a system / topic
  - an important design is genuinely uncertain (competing models, an undefined central concept)
    and writing a spec would be premature
  - an existing design forks and deeper exploration of a topic is wanted
metadata:
  maintainers: [bew]
---

# Skill: design-exploration

## Goal

Mature an immature design through an open-ended, proposal-first discussion loop, recording
findings, candidate directions, settled decisions, and open threads in topic-scoped
exploration files so a spec can later be written from settled ground.

## Phases

1. `Phase:Setup` — resolve identity, mode & path; seed files
2. `Phase:Explore` — per-topic discussion loop; write topic exploration files
3. `Phase:Wrap` — freeze settled topics; exit

**Vars used throughout**: (output them in context once known!)
- `$mode` — `adhoc` (no brief; topic files in the working dir) or `dedicated` (dir + brief).
- `$explodir` — directory for the exploration files (`adhoc`: the cwd).
- `$briefpath` — `$explodir/EXPLORATION-BRIEF.md`; `dedicated` mode only.
- `$topic` — current topic label, kebab-case lowercase.
- `$topicpath` — `$explodir/EXPLORATION-$topic.md`.
- `$name` — the design's human-readable name.
- `$slug` — the design's kebab-case slug.

## Interaction conventions

Apply in every phase.

- **Proposal-first.** Draft candidate ideas and rough shapes by default; state assumptions.
- Emit questions **inline** in the reply before reaching for the `question` tool.
- Use the `question` tool only at genuine mutually-exclusive forks.
  Keep it dismissible — the user may ignore it and answer in their own terms.
- Don't pre-create empty sections — fill them as content lands.
- Do not mandate `incremental-write` — its skeleton-first ceremony fights the fluid loop.
- Record decisions as they land; keep `Open threads` current.

## 1. `Phase:Setup` — resolve identity, mode & path; seed files

When entering `Phase:Setup`: read <./refs/phases/setup.md> for full instructions.

## 2. `Phase:Explore` — per-topic discussion loop

When entering `Phase:Explore`: read <./refs/phases/explore.md> for full instructions.

## 3. `Phase:Wrap` — freeze settled topics; exit

When entering `Phase:Wrap`: read <./refs/phases/wrap.md> for full instructions.
