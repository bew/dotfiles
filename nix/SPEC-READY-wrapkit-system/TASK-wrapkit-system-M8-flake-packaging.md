---
created-at: 20261102T0050
depends-on: task:wrapkit-system-M7-kit-half
---

# TASK: flake-packaging

Package wrapkit as a standalone flake at `nix/wrapkit-flake/`, with the output set and naming decided.

Settle the remaining output naming the spec leaves open, then author the flake exposing the kit and the embeddable modules through the `wraplib` output.
Packaging comes last, once the kit's output surface is stable.

## Tasks

- Decide the remaining output set and naming (settles the spec's placement open question).
- Author `flake.nix` at `nix/wrapkit-flake/`, exposing the helpers and module through the `wraplib` output plus the kit and the embeddable modules (variants per the `dynpaths` prior art).

## References

- `nix/SPEC-READY-wrapkit-system/MILESTONES.md` — milestone `M8`: Goal, Proof, ordering reason.
- `nix/SPEC-READY-wrapkit-system/SPEC.md` — spec context.
