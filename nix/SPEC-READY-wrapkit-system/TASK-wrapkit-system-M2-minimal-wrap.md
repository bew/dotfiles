---
created-at: 20261102T0050
depends-on: task:wrapkit-system-M1-research-merge
---

# [DONE] [CLAIMED] TASK: minimal-wrap

Turn a single `wrapper.env.<VAR>.set` record into a runnable wrapped binary at `$out/bin/<binName>`.

Build the smallest end-to-end slice: the mini-eval, the base module, the argument assembly, and the bin-dir builder working together.
It establishes the `mkWrapkit*` naming and the `wrapper.env.<VAR>.<action>` option paths the later milestones extend.

## Tasks

- Minimal `wrapperType` (`wrapper.env.<VAR>.set`).
- Resolve `binName`: default to the command name of the resolved binary; require it explicitly when `meta.mainProgram` is absent.
- `wrapkit-base.module.nix`: `wrapper` option, read-only `output`, `specialArgs` injection.
- `mkWrapkitBin`: `lib.evalModules` over the base module plus the caller record(s), returning `config.output`.
- bin-dir builder (`runCommandLocal` + `makeWrapper`).
- Test entry point using `pkgs.lib.runTests` (`nix eval -f`), matching `nix/kit-system/tests.nix`.

## References

- `nix/SPEC-READY-wrapkit-system/MILESTONES.md` — milestone `M2`: Goal, Proof, ordering reason.
- `nix/SPEC-READY-wrapkit-system/SPEC.md` — spec context.
