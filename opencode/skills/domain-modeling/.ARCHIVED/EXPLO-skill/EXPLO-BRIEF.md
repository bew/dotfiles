# Domain modelling skill — exploration brief

## Motivation

Draft a global OpenCode skill, `domain-modeling`, that actively builds a project's domain model:
challenge a term against the existing language, sharpen a fuzzy or overloaded word into one
canonical term, stress-test relationships with concrete scenarios, cross-check claimed behaviour
against the code, and write a settled term into the project's glossary as it lands.

Inspired by `mattpocock/skills` `engineering/domain-modeling`, re-cut for this config: no ADRs,
no glossary map, and the domain nouns carried by the skill itself rather than a separate vocabulary.

In scope: the skill body, its vocabulary, and the glossary file it writes.
Out of scope: the follow-up data-model design skill (`TASK-design-data-model-skill.md`), and any
change to `software-vocabulary`.

## Topics

- (frozen) `skill-shape` — what the skill owns, writes, and refuses
- (frozen) `vocabulary-terms` — the section names and the domain nouns the skill carries
