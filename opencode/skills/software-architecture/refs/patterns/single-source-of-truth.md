# single source of truth

## When it applies

The same value is stored twice, or the same decision is taken in two places: a counter and the list
it counts, a config and the parsed settings, a rule enforced at the entry point and again in the
worker.
They agree until one path changes alone.

## Shape

For a value: pick the `owner`; everything else is derived on read, or rebuilt as a whole.
Invalidation beats synchronisation.

```pseudocode
state.items      # the owner
len(state.items) # derived, never stored
```

For a decision: one module takes it, and callers ask rather than re-derive.
A decider may own a family of related rules; what it must not do is share that duty with a second
place that can drift.

```pseudocode
policy.price(order)   # decided once, asked by everyone
# not: the rate computed here, and again in the invoice view
```

When caching is required, the cache is keyed, droppable, and never authoritative.

Derived on read and cached are the same permission — a non-authoritative copy — and differ only
in cost and staleness.
When recomputing is expensive, cache it, and settle each of these:
- the key: which inputs it covers; a key missing part of the input is a collision.
- the lifetime: expiry or eviction; no expiry means drift.
- the miss: recompute from the `owner`, never from another copy.
- the writers: callers do not write it; if they do, it is a second owner.
- the warm-up: state built at boot and never rebuilt is kept in step by hand.

**Gain**: impossible states disappear instead of being validated, a bug report shrinks to "the owner
is wrong" rather than "which copy", a rule can be changed in one place — one file is not required,
one decider is — and a cache can be dropped at any moment without losing data.

## Pitfalls

- A cache that callers may write to.
- Two owners kept in step by a callback or a watcher; the watcher is the bug.
- Deriving on every read when the computation is expensive — cache it behind a key instead.
- Declaring one owner in the design and keeping a second "for convenience" inside one function.
- The same rule re-implemented where it is convenient; the copies drift at the first change.
