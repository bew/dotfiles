# side-effects at the edge

## When it applies

A decision cannot be tested without a clock, a file, or a network, or the same input yields
different results across two runs.
The deciding and the access are fused in one function, so neither can be checked alone.
A dependency must also be swapped — a fixed value, a fake, an in-memory version — to test the
behaviour around it.

## Shape

Two roles, not two layers: one decides over values it was handed, one performs the access.
They may live in the same module, but not in the same function.

Cut once per external concern, at the edge of the program, and pass the `adapter` in.
Side-effects become values before they become calls: read the clock once and pass a timestamp,
read the config once and pass a record.

```pseudocode
logic:    decisions over handed-in values   # no clock, env, fs, net, no globals
adapter:  reads inputs, calls logic, writes # thin, eyeballable
contract: one concern's operations          # now(), read(path), send(message)
```

Placement rules:
- the `contract` carries domain values, never the vendor's client
- the real `adapter` lives at the program edge; tests pass a fixed value or a dumb fake
- the fake holds no logic that could diverge from the real thing

What the dependency is decides how it is tested:
- **in-process** — merge it and test directly, no seam.
- **substituted** — clock, filesystem, environment, subprocess, randomness: inject it, and hand in
  a fixed version in tests.
- **remote but owned** — a real adapter in production, an in-memory one in tests.
- **true external** — inject the `contract`, use a mock adapter in tests.

A substitution used only by a module's own tests stays private and does not enter the `contract`.

**Example**:
```python
def plan_refund(order: Order, now: Timestamp) -> RefundPlan: ...
def apply_refund(plan: RefundPlan, gateway: Gateway) -> None: ...
```

**Gain**: the decision is testable through its `contract` alone — no fixtures, no temp dirs, no
fake clock — a wrong value localises to `logic` while a wrong file localises to the adapter, and
swapping an implementation becomes a construction-site change rather than a rewrite.

## Pitfalls

- A "pure" function taking a callback that touches the world: the side-effect moved, it was not
  removed.
- Passing a whole client into `logic` so it can fetch one thing.
- A seam per call instead of per concern — indirection with no test benefit.
- A fake richer than the real object, so the test proves the fake works.
- Seaming preemptively: a seam cut for a swap that never happened buys no test and no second
  adapter.
- A wrapper around a side-effect the test harness already supplies, such as captured output or a
  temporary directory: the harness was the second adapter, and the wrapper adds a layer with no
  test to show for it.
- Deferring the split until the deciding code is already hundreds of lines; the seam gets expensive.
- Over-cutting: a two-line script does not need a `logic` role at all.
