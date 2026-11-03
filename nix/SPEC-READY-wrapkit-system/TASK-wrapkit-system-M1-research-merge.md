---
created-at: 20261102T0050
---

# [DONE] [CLAIMED] TASK: research-merge

Resolve the per-action env-override merge question and pin the `makeWrapper` flag semantics the argument assembly relies on.

This is a research spike; the deliverable is its probe scripts under `findings/spikes/` plus the conclusions folded into `SPEC.md`, not production code.
Determine how a host's resolved env values reach the mini-eval without their materialized defaults colliding with inherited commons actions, and model the `makeWrapper` primitives the wrapper schema maps to.
Its conclusions gate every later milestone.

## Tasks

- Prototype per-action merge: raw definition modules vs resolved env values.
- Evaluate the input shapes (one inline `wrapper` record vs an ordered `wrappers` list of resolved records, and the rejected resolved-value adapter); choose the `wrapper` / `wrappers` interface.
- Probe `makeWrapper` flag semantics (`--prefix` vs `--prefix-each`, `--set`/`--prefix` interaction, ordering).
- Decide the default `binName` derivation rule.
- Fold the conclusions into `SPEC.md`.

## References

- `nix/SPEC-READY-wrapkit-system/MILESTONES.md` — milestone `M1`: Goal, Proof, ordering reason.
- `nix/SPEC-READY-wrapkit-system/SPEC.md` — spec context.
