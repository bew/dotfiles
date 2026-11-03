---
created-at: 20261102T0050
depends-on: task:wrapkit-system-M3-wrapper-schema
---

# [DONE] [CLAIMED] TASK: composition

Give `mkWrapkitBin` its two mutually exclusive record inputs, and make the per-action merge work in both.

The caller either writes one `wrapper` record inline (module priority, `lib.mkForce` for collisions) or hands over resolved records (`wrappers = [ … ]`), each normalised and applied as one definition apiece so the lists concatenate across layers.
An override that touches one action for a VAR inherits the commons' remaining actions.
This is the spec's top-priority goal.

## Tasks

- Assert `wrapper` and `wrappers` are mutually exclusive.
- Implement the normaliser (drop every `null` field and `unset = false`) that prepares each resolved record for application.
- Wire both inputs into the same mini-eval: the inline record as definitions, the layered records applied one definition apiece.
- Add inheritance tests to the entry point, for both modes.

## References

- `nix/SPEC-READY-wrapkit-system/MILESTONES.md` — milestone `M4`: Goal, Proof, ordering reason.
- `nix/SPEC-READY-wrapkit-system/SPEC.md` — spec context.
- `nix/SPEC-READY-wrapkit-system/SPEC.md` — Environment override model / Two module applications, not one, and / Clearing within one module application.
