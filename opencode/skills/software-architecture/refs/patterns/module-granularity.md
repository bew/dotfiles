# module granularity

## When it applies

A split is being proposed and modules multiply faster than concepts.
Signals:

- a module holds one class or two functions
- sibling modules share their constructor and their failure story
- one directory per kind, one entry under each
- a new file per verb

## Shape

Start from concept families, not from a menu of kinds.
Each module owns several related items that change together.

Floors and ceilings:

- Floor: about three related items or fifty lines.
  Below it a module is a `fragment`; fold it into its nearest owner.
- Ceiling: when a reader needs a map to find something, split.

Split lines that hold:

- a shared collaborator set, or a shared failure contract
- a part that is deletable, or has a distinct failure story
- a concept a reader would name in conversation

Split lines that do not hold:

- one module per verb
- one module per class
- one directory per kind

A `data module` holding a type and the helpers that act on it is one module, not two.

```pseudocode
# before: one module per kind, each holding one item
data/states      data/document    data/spec
adapters/printer adapters/mover
orchestrators/open orchestrators/edit orchestrators/move

# after: concept families, siblings merged
lifecycle   states, tables, prefixes, errors
document    the document type, its parse and render, its file access
spec        the spec type, its session values, the guards over them
operations  the orchestrator, the deletable migration, the move primitives
```

**Gain**: fewer places to look; each module has a name a reader remembers; boundaries line up with
the change that will cross them.

## Pitfalls

- A class promoted to a module because the design mentioned a role.
- A namespace class: one collaborator set, one method, a constructor existing only to pass the same
  two adapters.
- Kind-directories as the primary split, with one entry under each.
- Grouping by layer, so one change touches every directory.
- Counting modules as a sign of thoroughness.
