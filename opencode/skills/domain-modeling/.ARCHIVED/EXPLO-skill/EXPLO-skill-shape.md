# skill-shape — exploration

What the skill owns, what it writes into a project, and what it refuses to write.

## Findings

- The source skill pairs a project glossary with sparing ADRs, and draws a hard line at
  implementation detail: the glossary is a glossary, never a spec or a scratch pad.
- Its five session behaviours are challenge against the glossary, sharpen fuzzy language,
  discuss concrete scenarios, cross-reference with code, and update the glossary inline.
- `software-vocabulary` defines structural terms only (module, seam, owner, operation, …), has no
  domain nouns, and lives in the config repo rather than in each project.
- A per-project glossary and a config-wide structural vocabulary are different artefacts, so they
  do not compete for one file.
- `write-spec` owns durable design documents under a lifecycle tool; `design-exploration` owns
  pre-draft working records. A third decision artefact would give one decision three homes.
- The trigger description is the only text the agent reads before loading, so the read-versus-change
  line has to live there explicitly.

## Design crux

How little can the skill write while still leaving a model a future agent can read?

## Decisions

### (settled) `glossary-ownership` — a project glossary, domain terms only

A per-project `GLOSSARY.md` at the repository root, holding domain terms only.
`software-vocabulary` keeps the structural terms and is not merged, referenced as a source, or
duplicated.
The two never share a file because one is per-project state and the other is config-wide reference.

### (settled) `no-decision-artefact` — the glossary absorbs the why

The skill writes no ADR, no decision log, and no spec.
A settled distinction lands as a glossary entry: the definition carries the one clause that keeps
two terms apart, and `_Avoid_` carries the rejected word.
A decision that will not fit in a definition is not vocabulary, and stays with whatever skill is
already writing (design-exploration during exploration, write-spec for a durable design).

### (settled) `no-context-map` — nested glossaries, no map file

No `CONTEXT-MAP.md` and no `GLOSSARY-MAP.md`.
A repository may hold nested `GLOSSARY.md` files, one per directory scope, and the skill discovers
them by reading rather than through an index.
A term goes to a nested file only when every occurrence lies under that directory; any occurrence
outside, or none at all, keeps it at the root.
Nested glossaries were allowed during review, replacing the original one-glossary-per-repo rule.

### (settled) `ddd-nouns-location` — the domain nouns live in this skill

The DDD nouns are carried by this skill's own body.
Not a separate `ddd-vocabulary` skill, not an addition to `software-vocabulary`.
The reasoning: these nouns are specific to domain modelling, so a skill that never models a domain
should not pay to load them, and a structural term set should not grow a domain section.

### (settled) `trigger-line` — only when the model changes

The description loads the skill on a term that conflicts with existing language, a vague or
overloaded word needing one canonical name, a domain relationship under discussion, or writing or
editing the glossary, its entries, or the structural map of a term.
Reading a glossary for its vocabulary is out of scope, and the description says so.

### (settled) `install-scope` — global

`opencode/skills/domain-modeling/` in the dotfiles repo, beside `software-architecture` and
`software-vocabulary`.

## Open threads

- Which nouns the vocabulary section carries — `topic:vocabulary-terms`
- What the behavioural section is called — `topic:vocabulary-terms`
