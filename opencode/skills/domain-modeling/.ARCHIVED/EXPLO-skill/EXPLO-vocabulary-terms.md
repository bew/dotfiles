# vocabulary-terms — exploration

The two vocabularies the skill carries: the names of its own sections, and the domain nouns it
defines for the user.

## Findings

- The user rejected `Moves` as the section name for the behavioural part.
- Section-name inventory across the config: `## Goal`, `## Scope`, `## Rules`, `## Patterns`,
  `## Design frames`, `## Interaction conventions`, `## The loop`, `## Vocabulary`.
- `software-architecture` uses `frames` for decisions to make, explicitly "not a procedure to
  perform" — so `Frames` would mislabel a set of actions.
- The source skill contrasts itself with "a one-line habit any skill can do", so `Habits` names the
  thing this skill is not.
- The body carries three kinds of content and needs them visibly apart: the doing, the nouns, and
  the file it writes.
- The skill's two failure modes — one word for two concepts, and two words for one concept — have
  no name in `software-vocabulary` or in the source skill, yet they are exactly what the sharpening
  behaviour hunts.
- `aggregate` and `aggregate root` are in open conflict with `software-vocabulary`'s `one owner per
  value` unless the root is stated as the owner of everything inside it, and the consistency
  boundary is a data-shape decision.
- With no context map settled, `bounded context` has no artefact to point at; it would describe a
  file that does not exist.
- `domain event` is a modelling fact, but its decisions (delivery, ordering, durability) sit in the
  data-model skill, not here.
- Every noun costs a line on every load and carries a synonym risk, so a noun that names something
  the skill never asks about is a tax with no return.
- `invariant` is the only noun that makes a definition testable: it is the sentence that says which
  states must never exist.

## Design crux

Can one noun set serve both the skill's own structure and the user's domain, and stay small enough
that the skill does not read as a DDD primer?

## Decisions

### (settled) `behavioural-section-name` — `## Modelling`

The behavioural section is `## Modelling`, with each behaviour as an H3.
The H2 names the activity; the H3s name what is performed.
Shape parallels `## Design frames` in `software-architecture`, without borrowing the word `frames`,
which there means decisions to make rather than actions to perform.

### (settled) `domain-nouns` — six nouns, no aggregate

The vocabulary section carries `ubiquitous language`, `entity`, `value object`, and `invariant`,
plus `overloaded term` and `false synonym` as named failure modes.
The pair earns entries because the sharpening practice points at them, and because a merge is what
produces a selective `_Avoid_` line.
`aggregate` and `aggregate root` stay out: the consistency boundary is a data-shape decision, and
the follow-up data-model skill owns it.

### (settled) `borderline-nouns-out` — no `bounded context`, no `domain event`

Neither noun is carried now.
`bounded context` has no map or multi-context artefact to anchor it.
`domain event` carries decisions (delivery, ordering, durability) that belong to the data-model
skill.
Both can be added when their artefacts exist.

### (settled) `avoid-lines` — selective `_Avoid_`

A noun carries `_Avoid_` only where a real wrong word is already in circulation for it.
Not every entry gets one; the line exists to stop a synonym that is actually being used, not to
prove completeness.

## Rejected directions

- **`## Practices`** — accurate but flat; it names the genre rather than the skill's activity.
- **`## During the session` with bare H3s** — states when, not what; loses the grouping.
- **`## The loop`** — claims an iteration this skill does not have; each behaviour fires on its own
  situation.
- **Core six noun set** — `aggregate` needs a reconciliation clause against `one owner per value`,
  and the boundary it names is decided elsewhere.
- **Minimal three** — without `invariant`, no glossary definition is testable.

## Open threads

- None. Every direction on this topic is decided.
