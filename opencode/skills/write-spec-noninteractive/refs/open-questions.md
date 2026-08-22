# Open Questions format

Two kinds of open questions exist in a spec:

**Per-section Open Questions** — `### Open Questions` at end of any `##` section
that surfaces design decisions. These are specific to that section's domain.

**Global Open Questions** — `## Global Open Questions` at end of spec.
Covers broad unresolved decisions that span multiple sections.
They may escalate to **Blocking** during review if the reviewer judges them critical.

Each entry must include:

- Clear statement of unresolved decision.
- **Blocking** or **Non-blocking** — must this be resolved before implementation starts?
- Brief rationale: what is blocking the decision, or what tradeoff makes it non-obvious.

Remove or strike questions once resolved.

Example:

> 1. Should providers be allowed to deregister at runtime?
>    Non-blocking. No clear use-case yet; adding it costs lifecycle complexity that may never pay off.
