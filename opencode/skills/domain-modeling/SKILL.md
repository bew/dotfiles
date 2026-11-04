---
name: domain-modeling
description: |
  Sharpen a project's domain model and record each settled term in `GLOSSARY.md`.
  Load when a term conflicts with the existing language, a word carries two concepts, or two words
  carry one.
  Also load when the user asks to settle what a word means in this project, or asks to add a term to
  the glossary.
  Reading a glossary for vocabulary is not this skill.
metadata:
  maintainers: [bew]
---

## Goal

Leave the project's domain model sharper than it was found: every concept named once, every name
meaning one thing, and each resolution written into `GLOSSARY.md` as it lands.

## Modelling

Before any of these, find every `GLOSSARY.md` in the repository and read them all: a word defined in
one is defined for the project.
Apply these as the conversation calls for them, never as a fixed sequence.
When two apply at once, cross-check the code first; the rest take the order the conversation gives.

### Challenge the term against the glossary

When the user's word contradicts an entry, stop and quote both.
Name the entry, name the word, ask which meaning is right.
The entry stands until the user changes it.
With no glossary yet, nothing can contradict: there is nothing to challenge.

### Split an overloaded term

A word carrying two concepts is an `overloaded term`.
Name both concepts, propose one word for each.
Ask whether the original word keeps one concept, or retires in favour of both proposals.
Both resulting terms get their own entry.
A single entry covering both is the bug, not the compromise.

### Merge a false synonym

Two words carrying one concept are a `false synonym`.
Pick the word the code and the user actually say.
If they say different words, quote both and ask which one wins.
Put the other in `_Avoid_`.
Merging and splitting are the only things that produce an `_Avoid_` line.
When nothing yet says the dropped word, ask whether it belongs there anyway.

### Stress the relationship with a scenario

When a relationship is stated, invent a scenario that forces its boundary: a partial version, a
duplicate, a reversal, a thing that arrives late.
Ask what happens.
The answer either names the distinction or exposes the one still missing.
When one is still missing, name it before writing anything down.

### Cross-check the claim against the code

When the user states how something behaves, read the code that does it.
If the code cannot be located, say the claim is unverified: write the definition, drop the claim.
If code and claim disagree, quote both and ask which is intended.
The code is evidence, never the verdict: a wrong model is a common reason the code is wrong.

### Write the term down

Write a resolved term into the glossary it belongs to in the turn it is resolved.
Never batch resolutions; one lost to the next topic is lost.
Offer the entry text and write it once accepted.

## Vocabulary

The skill's own working terms, never written into a project glossary.

- `ubiquitous language` — the shared vocabulary of one project: the same words in conversation, in
  the glossary, and in the code.
- `entity` — a thing whose identity survives changes to everything else about it; two entities
  with equal fields are still two.
  `_Avoid_: record, object, model`
- `value object` — a thing defined entirely by its values, so two with equal fields are the same
  thing.
  `_Avoid_: DTO, struct, value`
- `invariant` — a rule that holds in every state the model may be in; a state that breaks it does
  not exist.
  `_Avoid_: constraint, validation rule`
- `overloaded term` — one word carrying two concepts.
- `false synonym` — two words carrying one concept.

## The glossary

Every `GLOSSARY.md` in the repository, root and nested, forms the project's glossary set.
A term goes to an existing nested glossary when every place it occurs lies under the directory
holding that file.
Any occurrence outside, or no occurrence at all, keeps the term at the root.
Occurrences count code identifiers and prose mentions, matched case-insensitively.
Create the root file when a term routes there.

The file:

```md
# Glossary

Scope: order intake, pricing, and fulfilment.

What each thing in this scope is called, and what that name means.

**Order**: a request to buy one or more items, priced when it was placed.
_Code_: `Order`, `order_lines`
_Avoid_: Purchase, Transaction

**Shipment**: the movement of one order's items to one address.
```

- Rank each new entry by its importance in the project.
  Existing entries keep their place; ask before moving one that has turned out far less
  load-bearing.
- One blank line between entries.
- Group entries under `##` headings only when the user asks for it.
  In a grouped file an entry goes inside the group it belongs to; ask when it fits two.
- The `Scope:` line is a noun phrase naming the domain; draft it when creating the file and let the
  user correct it.
  Under it, one line says what the file is: the reference of terms for this scope.
  A file without a `# Glossary` heading, a `Scope:` line, or that hint line: ask before adding them.
- The term and its `_Avoid_` words are prose: capitalise the first letter.
- A `_Code_` line lists the identifiers that carry the term, spelled as the code spells them.
  Omit it when no code names the term.
- One or two sentences per entry.
  Say what the thing is; where the term carries invariants, name the states that must never exist.
- Domain terms only.
  Timeouts, retries, and error types are general programming, not this project's language.
- An `_Avoid_` line only where a wrong word is already in circulation.
  Do not add one to prove completeness.
- A word already defined in another glossary is a scope conflict: ask before defining it again.

### Point AGENTS.md at the glossary

Name each glossary file in the nearest `AGENTS.md` at or above its directory.
That is the repo root's `AGENTS.md` when nothing sits closer.
That file carries one `## Domain language` section.
Append it at the end of the file when absent; update it in place when present.
Spell each bullet's path relative to the `AGENTS.md` holding it.
Never add a second section or a second copy of a bullet it already holds.

```md
## Domain language

Read these before naming anything; settle new terms here.

- `GLOSSARY.md` — order intake, pricing, and fulfilment.
- `services/billing/GLOSSARY.md` — invoices and payments.
```

The section opens with the line saying when to read the glossaries; add it when missing.
One bullet per glossary file, naming its scope as the file's `Scope:` line states it.
Inside the section, a bullet naming a glossary file is the mention: refresh it, never add another.
Glossary paths outside the section are unrelated prose: leave them alone.
Refresh the section when a glossary is created or its scope changes.
With no `AGENTS.md` at or above the glossary: say what to add and where, then stop.
Do not create the file.

## Rules

- When two readings fit and no rule here decides between them, ask the user; never pick one
  silently.
- This skill writes glossary files and the `AGENTS.md` mention of them.
  Nothing else: a decision that will not fit a definition is not vocabulary, and stays with
  whichever skill is already writing.
- Structural terms — module, seam, owner, operation — belong to `software-vocabulary`.
  Never add them to a project glossary.
- Never invent a term the user has not accepted, and never write an entry for a term merely
  mentioned in passing.
- Edit the existing file; never rewrite a glossary wholesale.
  Keep entries this skill did not write, and ask before removing an accepted term.
- One word, one meaning, across every glossary.
  The same word meaning two things is an `overloaded term`, whatever the files say.
