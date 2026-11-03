---
created-at: 20261102T0050
depends-on: task:wrapkit-system-M2-minimal-wrap
---

# TASK: layout-single-file

Emit the executable directly as `$out` when `binName = null` (Layout 1).

Add the second, opt-in output layout by branching the base builder on `binName`.
It is independent of the schema and composition work; it needs only the builder from the minimal slice.

## Tasks

- Branch the builder on `binName`: Layout 1 vs Layout 2.
- Add a layout assertion to the test entry point.

## References

- `nix/SPEC-READY-wrapkit-system/MILESTONES.md` — milestone `M5`: Goal, Proof, ordering reason.
- `nix/SPEC-READY-wrapkit-system/SPEC.md` — spec context.
