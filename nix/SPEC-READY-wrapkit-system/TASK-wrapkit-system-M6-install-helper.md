---
created-at: 20261102T0050
depends-on: task:wrapkit-system-M4-composition
---

# [DONE] [CLAIMED] TASK: install-helper

Package the `wrapper` record option as `mkWrapkitWrapperOption`, so a host declares it like any other option, at any site and under any name.

Expose the composition mechanism as a reusable record option so a host declares its commons and per-site overrides from the same source.
This follows once the merge itself is proven.

## Tasks

- Implement `mkWrapkitWrapperOption { }` returning the record option (`lib.mkOption { type = wrapperType; default = {}; }`), and use it for the base module's own `wrapper` option.
- Expose `mkWrapkitWrapperOption` publicly (part of the `wraplib` export in M7).

## References

- `nix/SPEC-READY-wrapkit-system/MILESTONES.md` — milestone `M6`: Goal, Proof, ordering reason.
- `nix/SPEC-READY-wrapkit-system/SPEC.md` — spec context.
