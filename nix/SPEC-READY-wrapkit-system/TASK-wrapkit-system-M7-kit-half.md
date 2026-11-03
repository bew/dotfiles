---
created-at: 20261102T0050
depends-on: task:wrapkit-system-M4-composition
---

# TASK: kit-half

Make wrapkit consumable as a kit — its own evaluation and `lib.extendWith` support — and expose the `wraplib` export (helper functions).

The kit's evaluation is separate from the per-bin mini-evals; build the kit on `nix/kit-system`.

## Tasks

- Build the kit on `nix/kit-system` (`newKit`/`defineEval`), on its own evaluation separate from the per-bin mini-evals.
- Expose `wraplib` (the helper functions) from `nix/kits/wrapkit/default.nix`.

## References

- `nix/SPEC-READY-wrapkit-system/MILESTONES.md` — milestone `M7`: Goal, Proof, ordering reason.
- `nix/SPEC-READY-wrapkit-system/SPEC.md` — spec context.
