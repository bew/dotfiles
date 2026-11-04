# shared-vocabulary — exploration

Whether the term set stays inside `software-architecture`, or becomes the repo's shared
language for talking about software structure.

Opened after the other topics were frozen: the terms were settled there, their home was not.

## Findings

- A skill loads on demand, so it is present only when its description matches the task.
  A shared language wants to be present every time software structure is discussed.
- No skill can force another skill to load, so a "load X first" line inside a skill is a
  request, not a guarantee.
- The design skill's pattern entries use `contract`, `seam`, `adapter`, `owner`, `logic`, and
  define none of them once the vocabulary moves out.
- A glossary-only skill is a new artefact shape here: existing skills carry procedures or rule sets.
- `skill-standalone` cannot reference another skill's files, so a standalone export of the design
  skill would ship without its own language.
- Cross-links were previously rejected inbound into the design skill (`topic:skill-positioning`);
  this topic is about a new artefact with its own discovery, not about reopening that call.

## Design crux

A single source of terms and a guaranteed presence are incompatible: the source can be one file,
but its presence depends on either duplication or a pointer someone follows.

## Candidate directions

None live.

## Decisions

### (settled) `vocabulary-as-own-skill` — the terms live in `software-vocabulary`

A new skill at `opencode/skills/software-vocabulary/` holds the six frames, every term with its
`_Avoid_:` line, and the rejected-framings block.
It carries no procedure and no design advice.

`software-architecture` deletes its `## Vocabulary` section and gains one line near the top:
this skill speaks in the terms of `software-vocabulary`, load it if it is not already in context.
Every pattern ref and `refs/design-it-twice.md` inherits the language with no pointer of its own.

Why: the terms outlive the design skill — they are how structure gets discussed at all — and a
single copy is the only thing that stops two word sets drifting.

Accepted cost: an agent that skips the pointer reads `seam` and `adapter` as ordinary English.
The skill still reads, less precisely. This was chosen over duplicating definitions, which would
reintroduce the drift the split exists to prevent.

### (settled) `vocabulary-reference-design-only` — only the design skill names the vocabulary

`software-architecture` is the only skill carrying the pointer.
`write-spec`, `coder-generic`, and `design-exploration` are left untouched.

Why: the design skill is the one whose every line depends on the terms, so a miss there is visible.
Adding pointers elsewhere would make the vocabulary a dependency of skills that write about
structure occasionally.

Accepted cost: `write-spec` and `design-exploration` keep their own wording for contracts and seams,
so drift is possible in the documents they produce.

### (settled) `vocabulary-description-self-triggering` — broad description plus one pointer

The `software-vocabulary` description fires on its own for tasks that choose or argue about the
words for software structure, naming a few terms so it matches a real prompt.
It also states that it is the term set the design skill refers to.

Why: the pointer alone is unreliable and the description alone is unpredictable, so the skill has
two ways to be loaded and neither is load-bearing on its own.

Accepted cost: a broad description competes with `coder-generic` and `software-architecture`
for the same tasks, so three skills can load on one prompt.

## Open threads

- Skill name: `software-vocabulary` versus a shorter noun that reads well in prose.
- Does the design skill's pointer belong in `## Scope`, in a preamble line above it, or in its
  description?
- Does a glossary with no procedure need any section beyond `## Vocabulary`?
