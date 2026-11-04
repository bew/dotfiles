# data over flags

## When it applies

A boolean or mode string travels down several stackframes so a deep function can behave differently.
Each new case adds a parameter, a branch, and a caller that must remember the combination.
Every callee between the entry point and the branch has to carry the flag without using it.

## Shape

Resolve the variation once, at the entry point, into data; inner code consumes the record and
branches nowhere.
When the cases are a closed set, a table keyed by case replaces the if-chain.

```pseudocode
# before: the flag travels three levels, each stackframe forced to carry it
render(doc, flag) -> render_section(section, flag) -> render_item(item, flag)

# after: decided once at the entry point; inner code reads the record
options = resolve_options(request)
render(doc, options)
```

**Example**:
```python
HANDLERS: dict[EventKind, Callable[[Event], Operation]] = {...}
```

**Gain**: callers name the variation instead of encoding it positionally, a new case extends a table
rather than a branch tree, and options are constructible in a test without a call stack.

## Pitfalls

- Two related booleans collapsed into a record that still allows all four combinations; use an enum
  for the cases.
- Passing the record deeper than needed instead of deriving what the callee requires.
- Data where the variation is genuinely one condition — a record is overhead.
