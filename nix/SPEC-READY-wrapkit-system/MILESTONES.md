# wrapkit-system — implementation milestones

## Sources

- Spec: `nix/SPEC-READY-wrapkit-system/SPEC.md`
- Related: `nix/SPEC-READY-wrapkit-system/EXPLO-BRIEF.md`, `EXPLO-env-override-model.md`, `EXPLO-wrapped-drv-generator.md`, `EXPLO-wrapper-schema.md`, `EXPLO-packaging-composition.md`
- Related: `nix/mypkglib.nix` — current shared wrapped-pkg builder (`replaceBinsInPkg`).
- Related: `nix/kits/toolkits.nix`, `nix/kits/toolkit-modules/{tmuxkit,zshkit,nvimkit}-base.toolkit-module.nix` — the drifted per-toolkit wrapper blocks.
- Related: `nix/kit-system/default.nix` — `newKit`, `defineEval`, `lib.extendWith`; the kit half's substrate.
- Related: `nix/DESIGN_config_system.md` — Kit/Module/Preset/Profile/Config vocabulary.
- Related: `nix/kit-system/default.nix` — `newKit`, `defineEval`, `lib.extendWith`; the kit substrate the mini-eval runs on.
- Related: `nix/SPEC-DRAFT-hm-toolconfigs-integration-CRAZY!/SPEC.md` — sibling draft on per-home output recomputation.
- Related: nixpkgs `pkgs/build-support/setup-hooks/make-wrapper.sh` — the primitives the wrapper schema models.

## Dependency Graph

- `research-merge` (M1): spike on per-action wrapper-record merge (inline definitions vs layered resolved records) + `makeWrapper` primitives; output is written findings.
  No dependency.
- `minimal-wrap` (M2): one module with `wrapper.env.<VAR>.set` → runnable wrapped bin in bin-dir layout; establishes `mkWrapkit*` naming, option paths, and the minimal `wrapperType`.
  Depends on: `research-merge`.
- `wrapper-schema` (M3): full `makeWrapper` surface (all env actions, `flags`, process control) → complete arg assembly; expands `wrapperType`.
  Depends on: `minimal-wrap`.
- `composition` (M4): the two record inputs — an inline `wrapper` merged by module priority, or `wrappers = [ resolved records ]` normalised and applied one definition apiece — with per-action inheritance.
  Depends on: `wrapper-schema`.
- `layout-single-file` (M5): single-file `$out` (`binName = null`).
  Depends on: `minimal-wrap`.
- `install-helper` (M6): `mkWrapkitWrapperOption` as a reusable record option for any install site.
  Depends on: `composition`.
- `kit-half` (M7): wrapkit as a kit on `kitsys` — `lib.extendWith` support — plus the `wraplib` export (helpers).
  Depends on: `composition`.

## Out of Scope

- Migrating the three existing toolkits onto wrapkit: the spec describes wrapkit itself, not a migration plan.
- Single-bin → package composition (`mkWrapkitPkg`): explicitly outside wrapkit's single-bin target.
- Defining `profiles.*`: the profile system is external; wrapkit supplies only constructors.
- Ordered-action-list env schema variant: deferred in favor of the per-VAR action submodule.
- A Terminology & Key Concepts section: a spec concern (now present in the spec), not an implementation milestone.
- CI wiring: the repo has no CI; verification is via the `nix eval`/`nix build` commands in each milestone's Proof.

----

## M1 — research-merge

**Goal**: Findings pin the per-action wrapper-record merge mechanism — inline definitions merged by module priority with `lib.mkForce` for colliding actions, and layered resolved records normalised and applied one definition apiece — and the `makeWrapper` flag semantics the argument assembly relies on.

**Ordering reason**: Placed first because the per-action override merge is the spec's top-priority goal and its mechanism is the only genuinely unresolved part of the design; the rest of the plan builds on its conclusions.

**Finished**: The M1 probe scripts under `nix/SPEC-READY-wrapkit-system/findings/spikes/`, with their conclusions folded into `SPEC.md` — the per-action wrapper-record merge, the `makeWrapper` flag semantics, and the default `binName` rule.

**Proof**:
- Run the spike prototype expression with two raw definition modules (commons sets `env.FOO.prepend`, override sets `env.FOO.set`) — observe the effective env and assembled args carry both actions.
- Pass a resolved record into the module system unnormalised — observe the eval fails with conflicting definitions, showing why a resolved value cannot be applied as a definition until its null fields are stripped.
- Run a minimal `makeWrapper` invocation with `--set` plus `--prefix` — observe the resulting environment confirms the de-dup and ordering the schema notes claim.
- Read the conclusions in `SPEC.md` — confirm the merge mechanism is chosen with rationale, and that `binName` derivation is stated for both a path string and a derivation.

**Tasks**: [TASK-wrapkit-system-M1-research-merge.md](./TASK-wrapkit-system-M1-research-merge.md)

## M2 — minimal-wrap

**Goal**: A single module defining `wrapper.env.<VAR>.set` is turned by `mkWrapkitBin` into a runnable wrapped binary at `$out/bin/<binName>` (bin-dir layout), with the `mkWrapkit*` naming and option paths established.

**Ordering reason**: The smallest end-to-end slice that exercises the mini-eval, the base module, the argument assembly, and the bin-dir builder together; it de-risks the plumbing before the schema grows.

**Finished**: `mkWrapkitBin` (minimal `wrapper` surface); `wrapkit-base.module.nix` (declares `wrapper` + read-only `output`, injects `wrappedBin`/`binName`); the `mkWrapkit*` naming and `wrapper.env.<VAR>.<action>` option paths; `binName` resolution (default from the resolved binary; explicit required when `meta.mainProgram` is absent); a runnable wrapkit test entry point.

**Proof**:
- `nix build` a wrapkit expression with `wrapper.env.FOO.set = "bar"` — observe `$out/bin/<binName>` exists and is executable.
- Run that binary printing its environment — observe `FOO=bar`.
- `nix eval` of `lib.getExe <the wrapped bin>` — observe it resolves to the built path.
- Run the wrapkit test entry point — observe the assertions pass and the naming follows the documented conventions.

**Tasks**: [TASK-wrapkit-system-M2-minimal-wrap.md](./TASK-wrapkit-system-M2-minimal-wrap.md)

## M3 — wrapper-schema

**Goal**: The full `makeWrapper` surface — every env action, `flags`, and process control — is expressible and assembled into a correct wrapper-argument list.

**Ordering reason**: Completes the wrapper-vocabulary model after the end-to-end slice works, and gives composition the multiple actions it needs to demonstrate per-action inheritance.

**Finished**: `wrapperType` complete — every env action (`set`, `setDefault`, `unset`, `prepend`, `append`, `prependFromFile`, `appendFromFile`) with per-VAR `sep`; `flags` (`beforeArgs`, `afterArgs`); process control (`argv0`, `chdir`, `run`); the wrapper-argument assembly mapping each to its `makeWrapper` flag, with `beforeArgs`/`afterArgs` emitted as one singular `--add-flag`/`--append-flag` per element and `sep` validated as a non-empty single character.

**Proof**:
- Run the wrapkit test entry point — arg-assembly assertions for every action pass, each mapping to the expected flag.
- `nix build` a bin using `flags.beforeArgs`, `argv0`, `chdir`, and `run` — observe each takes effect when the bin is run.
- `nix build` a bin using `prepend` with a non-default `sep` — observe one `--prefix` with the list joined by `sep`.
- `nix build` a bin with a `flags.beforeArgs` element containing spaces or quotes — observe it arrives as a single argument.
- Pass an empty or multi-character `sep` — observe a clear validation error.

**Tasks**: [TASK-wrapkit-system-M3-wrapper-schema.md](./TASK-wrapkit-system-M3-wrapper-schema.md)

## M4 — composition

**Goal**: The two record inputs of `mkWrapkitBin` both deliver per-action inheritance: an inline `wrapper` merged by module priority, and `wrappers = [ resolved records ]` normalised and applied one definition apiece, so an override that sets one action for a VAR inherits that VAR's other actions from an earlier record.

**Ordering reason**: This is the spec's priority-#1 goal; it needs the full schema in place to show an override touching one action while the rest survive.

**Finished**: The two-mode per-action merge inside `mkWrapkitBin` — module priority for an inline `wrapper` record, normalise-then-apply for ordered resolved `wrappers` — behind a mutual-exclusion assert.

**Proof**:
- Run the wrapkit test entry point with a commons module (`env.FOO.prepend`) and an override module (`env.FOO.set`) passed separately — observe the assembled args carry both.
- `nix build` and run that bin — observe `FOO` is the override's `set` value while its `prepend` still includes the commons entry.
- Run the test with a colliding `lib.mkForce` override — observe the override wins that action while the commons' other actions survive, and that omitting `mkForce` fails the eval.
- Run the same test in layered mode with `wrappers = [ config.wrapper config.profiles.<name>.wrapper ]` — observe both actions survive, with layer order deciding only the order of accumulated lists.

**Tasks**: [TASK-wrapkit-system-M4-composition.md](./TASK-wrapkit-system-M4-composition.md)

## M5 — layout-single-file

**Goal**: With `binName = null`, `mkWrapkitBin` emits the executable directly as `$out` (single-file layout).

**Ordering reason**: A second, opt-in output layout independent of the schema and composition work; it only needs the base builder from the minimal slice.

**Finished**: The single-file builder — `binName = null` makes `$out` the executable file.

**Proof**:
- `nix build` with `binName = null` — observe `$out` is an executable regular file and running it works.
- Observe no `$out/bin` directory exists.

**Tasks**: [TASK-wrapkit-system-M5-layout-single-file.md](./TASK-wrapkit-system-M5-layout-single-file.md)

## M6 — install-helper

**Goal**: `mkWrapkitWrapperOption` returns the `wrapper` record option, so a host declares its commons and per-site overrides from the same source, at whatever sites and names it likes.

**Ordering reason**: Packages the composition mechanism as a reusable record option after the merge itself is proven.

**Finished**: `mkWrapkitWrapperOption` returning the record option, used by the base module and by a host, and publicly exported (part of the `wraplib` export in M7).

**Proof**:
- `nix eval` a host eval with `{ options.wrapper = mkWrapkitWrapperOption { }; }` — observe `config.wrapper.env.FOO.set` is accepted.
- `nix eval` the same with a differently named nested field (`{ options.profiles.foo.cfg = mkWrapkitWrapperOption { }; }`) — observe `config.profiles.foo.cfg.env.FOO.set` is accepted.
- Confirm the constructor is publicly exported.

**Tasks**: [TASK-wrapkit-system-M6-install-helper.md](./TASK-wrapkit-system-M6-install-helper.md)

## M7 — kit-half

**Goal**: Wrapkit is consumable as a kit — built on `kitsys` with `lib.extendWith` support — and exposes the `wraplib` export (helper functions).

**Ordering reason**: The kit half wraps the working helpers, so it follows composition and the install helper; the kit shape is settled (one `kitsys` kit the mini-evals run through), so the milestone is a straight build.

**Finished**: The wrapkit kit built on `kitsys` — the mini-evals run through it — with `lib.extendWith` support, and the `wraplib` export holding the helper functions.

**Proof**:
- `nix eval` a `mkWrapkitBin` call — observe it returns `{ config; drv; }` and the drv builds.
- Extend the returned config with `lib.extendWith` — observe the refined config re-evaluates.
- `nix eval` the `wraplib` export — observe the helper functions are present.
- Confirm each `mkWrapkitBin` call runs the one kit with `wrappedBin` and `binName` as module args.

**Tasks**: [TASK-wrapkit-system-M7-kit-half.md](./TASK-wrapkit-system-M7-kit-half.md)

**Future work**: Migrating the three toolkits onto wrapkit (out of scope) is the eventual consumer of this kit.
