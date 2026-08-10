# Open Questions format

Open Questions appear throughout the spec — in any `### Open Questions` subsection under a section where design decisions remain unresolved.
They are not specific to Alternatives & Tradeoffs.

Each entry must include:

- Clear statement of unresolved decision.
- **Blocking** or **Non-blocking** — must this be resolved before implementation starts?
- Brief rationale: what is blocking the decision, or what tradeoff makes it non-obvious.

Remove or strike questions once resolved.

Example:

> 1. Should providers be allowed to deregister at runtime?
>    Non-blocking. No clear use-case yet; adding it costs lifecycle complexity that may never pay off.
