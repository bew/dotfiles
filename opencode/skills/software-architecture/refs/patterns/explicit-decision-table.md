# explicit decision table

## When it applies

A `lifecycle` is encoded as booleans — `is_draft`, `is_published`, `was_published`,
`is_archived` — where most combinations are illegal, and every new rule adds another guard.

A decision tree is scattered across functions: the same conditions are tested in several places,
each function knows part of the rule, and no single place says what the outcome is for a given
input.

## Shape

One place holds the rule; every other module consults it rather than re-deriving it.

A `lifecycle` becomes one state value and one table of allowed transitions.

```pseudocode
State      = { Draft, Reviewed, Published, Archived }
legal(from, to) -> bool
next(state, event) -> Result<State, Refusal>
```

**Example**:
```python
LIFECYCLE: dict[State, frozenset[State]] = {
    State.DRAFT: frozenset({State.REVIEWED}),
    State.REVIEWED: frozenset({State.DRAFT, State.PUBLISHED}),
    State.PUBLISHED: frozenset({State.ARCHIVED}),
    State.ARCHIVED: frozenset(),
}
```

A stateless tree becomes one table from condition to outcome, and one function that consults it.

```pseudocode
Outcome    = { Accept, Refuse(reason) }
decide(input) -> Outcome   -- walks one table; the rule is branched nowhere else
```

Side-effects sit beside the table, never inside the function that consults it.

**Gain**: one place answers the question; illegal combinations stop being representable; tests
enumerate rows instead of inventing boolean permutations; a new case is one table entry, not a
guard added in every caller.

## Pitfalls

- Modelling orthogonal dimensions as one axis — publication state versus visibility is two
  machines.
- Side-effects inside the transition function, so a retried event fires them twice.
- A machine with one legal path; a plain sequence says more and costs less.
- Forgetting the terminal state, so "archived" quietly accepts everything.
- A second table or guard list for the same rule, so the rule is still decided in two places.
- A table for a rule with one condition and one outcome; an `if` said it in a line.
