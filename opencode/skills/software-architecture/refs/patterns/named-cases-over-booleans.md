# named cases over booleans

## When it applies

A boolean parameter picks between behaviours: `parse(text, True)`.
The call site no longer says which behaviour it asked for, and a second boolean makes the
combinations unreadable and partly illegal.
A named case also leaves room to add a behaviour later without growing the parameter list.

A single obvious toggle on a small `contract` or a named parameter is fine as a boolean;
this pattern is about parameters that choose what the code does.

## Shape

Replace the boolean with a value from a closed set, named for the behaviour.
The callee switches on that one value, so contradictory requests cannot be expressed.

```pseudocode
before: parse(text, strict: bool, keep_comments: bool)   # 4 combinations, 1 illegal
after:  parse(text, mode: ParseMode)                     # one value, named at the call site
```

**Example**:
```python
class ParseMode(Enum):
    STRICT = auto()
    LENIENT = auto()

def parse(text: str, mode: ParseMode) -> Document: ...
```

**Gain**: the call site names its intent, illegal combinations cannot be built, and adding a case
is a change to one type rather than a flag every caller must learn.

## Pitfalls

- Squeezing orthogonal options into one case type; two independent choices stay two parameters.
- Keeping the old boolean signature as a wrapper, so the unnamed call survives in new code.
- A case type with one member: that is a rename, not a decision.
- Cases that differ only in a detail the callee could compute, which turns a mode into a setting.
- Naming cases for a parameter that will never grow, where a plain boolean carried the same meaning.
