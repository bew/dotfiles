# software-architecture skill — exploration brief

## Motivation

Designing a new `software-architecture` skill: guidance on structuring code, distinct from `coder-generic`
conventions and from `write-spec` documents.
Current state: a draft exists in a temp crafter dir with `SKILL.md`, five "design moves",
a six-entry pattern index under `refs/patterns/`, rules and guidelines, and a Python-as-pseudocode
note.

Inspiration studied: `mattpocock/skills` → `skills/engineering/codebase-design`
(`SKILL.md`, `DEEPENING.md`, `DESIGN-IT-TWICE.md`), a vocabulary-first deep-module skill.

Scope of this exploration: decide, topic by topic, which ideas from that skill are worth keeping and
in what shape, before the draft is rewritten.

Out of scope: implementing the `manage-spec` module split, and any change to `coder-*` skills.

## Topics

- (frozen) `skill-positioning` — triggers, scope vs sibling skills, output artefacts, cross-links
- (frozen) `vocabulary-nouns` — which nouns are kept, renamed, or dropped, and what each one means
- (frozen) `vocabulary-and-depth` — glossary placement, depth/leverage/locality, deletion test,
  rejected framings
- (frozen) `seams-and-testing` — seam discipline, adapters, dependency categories, test surface
- (frozen) `skill-anatomy` — section list and order, rules and vocabulary grouping, line budgets
- (frozen) `design-process` — design moves, critique behaviour, design-it-twice protocol
- (frozen) `pattern-catalogue` — which patterns survive, entry format, granularity
- (frozen) `shared-vocabulary` — whether the terms stay inside the design skill or become a
  skill of their own
- (active) `data-shape` — what the `Decide the data shape` frame must decide, and whether that
  reasoning lives in the frame or in an entry behind it
- (frozen) `output-structure` — the shape of what the frames end with, and what to call it
