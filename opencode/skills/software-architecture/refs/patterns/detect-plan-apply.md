# detect → plan → apply

## When it applies

An `orchestrator` must decide which operations to run from the current state, then run them, and you
would want to see those decisions before they are carried out.

## Shape

The deciding step is pure: it reads the state it is given and the requested change, and returns an
ordered list of `operation` records.
Each record is plain data — a kind, a target, and a payload, for example.
Prefer no live object in it; a plan that stands on its own stays assertable.
An empty list is the no-op, so the plan needs no extra predicate.
The `orchestrator` then walks the list and calls the adapters, without re-deciding on the way.

```pseudocode
state = detect(input or adapters) # read only, never writes
plan  = plan(state, intent)  # gives list of operation records
apply(plan, adapters)        # execute the listed operations (after user confirmation)
```

**Example**:
```python
@dataclass(frozen=True)
class Operation:
    kind: OperationKind
    target: Path
    payload: str | None = None
```

**Gain**: the plan is assertable without touching the system, so the deciding is tested and the
`orchestrator` stays thin enough to read.

## Pitfalls

- `detect` that writes — creating directories or touching timestamps defeats the split.
- `apply` re-deriving decisions instead of consuming the plan, which makes the plan a lie.
- Chained operations whose planning needs the previous step applied; either make each record
  self-sufficient or accept multi-phase planning and say so.
- One record per trivial write, producing a plan longer than the work; group by user-visible intent.
