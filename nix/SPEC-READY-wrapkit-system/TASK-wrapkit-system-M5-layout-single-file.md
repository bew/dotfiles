---
created-at: 20261102T0050
depends-on: task:wrapkit-system-M2-minimal-wrap
---

# [DONE] [CLAIMED] TASK: layout-single-file

Emit the executable directly as `$out` when `binName = null` (single-file layout).

Add the second, opt-in output layout by branching the base builder on `binName`.
It is independent of the schema and composition work; it needs only the builder from the minimal slice.

## Tasks

- Branch the builder on `binName`: single-file vs bin-dir layout.
- Add a layout assertion to the test entry point.

## References

- `nix/SPEC-READY-wrapkit-system/MILESTONES.md` — milestone `M5`: Goal, Proof, ordering reason.
- `nix/SPEC-READY-wrapkit-system/SPEC.md` — spec context.
