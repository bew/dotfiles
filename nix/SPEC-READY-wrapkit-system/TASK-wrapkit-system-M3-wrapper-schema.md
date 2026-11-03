---
created-at: 20261102T0050
depends-on: task:wrapkit-system-M2-minimal-wrap
---

# [DONE] [CLAIMED] TASK: wrapper-schema

Model the full `makeWrapper` surface and assemble it into a correct wrapper-argument list.

Expand the option schema from the minimal `set` action to every env action, `flags`, and process control, mapping each to its `makeWrapper` flag.
This gives composition the multiple actions it needs to demonstrate per-action inheritance.

## Tasks

- Expand `wrapperType` to the full action set with per-VAR `sep`.
- Add `flags` and the top-level process-control options.
- Implement the wrapper-argument assembly (singular `--add-flag`/`--append-flag` per element; validate `sep` as a non-empty single character).
- Extend the test entry point with per-action assertions.

## References

- `nix/SPEC-READY-wrapkit-system/MILESTONES.md` — milestone `M3`: Goal, Proof, ordering reason.
- `nix/SPEC-READY-wrapkit-system/SPEC.md` — spec context.
