# data vs behaviour

## When it applies

A data type grows a method that writes, prints, moves, or decides an order.
Or an orchestrator is being written as a record of fields.

## Shape

Two kinds of module:

- a `data module` holds fields and derived values.
  A derived method takes values in and returns values out, with no ordering and no access to the
  outside world.
- an `orchestrator` constructs data, calls `logic`, uses `adapters`, and owns order and failure.

Where the line falls:

- Data derives from its own fields, and may reject a shape those fields cannot satisfy.
  It never sees a world.
- `logic` decides, and may refuse, using values from more than one owner or from the world.
- An `orchestrator` owns the workflow rules; it decides what happens next, never whether the state
  is valid.

Data is frozen: a derivation returns the next value, and the orchestrator binds it.
Nothing downstream can mutate a value it was handed, so no stale copy exists.

```pseudocode
# data: derives, never acts
document.for_state(state) -> Document
spec.with_document(document) -> Spec

# orchestrator: acts, owns order
Class SpecRewriter:
    retag(spec, state):
        next = spec.document.for_state(state)
        write(spec.spec_path, next)
        return spec.with_document(next)
```

Separation is per class, not per file.
A helper that acts on the data may sit beside it, as long as the data type itself stays inert.

A data type guards its own shape when the check needs nothing external: a required field present, a
value in range, one of two named forms.
That check belongs to the type's contract, and every instance is valid by construction.
Python's `pydantic.BaseModel` is the familiar form; a hand-written constructor check is the same
idea.
Validation that needs the world — does this path exist, is this name taken — stays outside, in
the module that reads the value.

**Gain**: data is constructible in a test with no filesystem and no clock; ordering lives in one
module; a frozen value cannot drift between two owners.

## Pitfalls

- A record method that saves, prints, or sequences.
- A mutable record beside an orchestrator: two owners of one value.
- An orchestrator per verb, each rebuilding the same collaborators.
- Pushing every helper away from the data for the sake of purity, leaving the data type with no
  home.
- Validation in the data constructor that needs the world, such as an existing path or a free name:
  the value can no longer be built in a test without that world.
- A required shape left unchecked because validation was pushed outside the type.
