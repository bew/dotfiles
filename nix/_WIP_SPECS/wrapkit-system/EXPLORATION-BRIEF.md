# wrapkit-system — exploration brief

## Motivation

Pre-spec exploration feeding a future `SPEC.md` in this directory.
Records findings and the design discussion; feeds the spec later.

- **Name**: wrapkit-system.
- **Slug / dir**: `nix/_WIP_SPECS/wrapkit-system/`.
- **Scope**: one spec covering both the module-system design and the standalone-flake packaging.
- **Nature**: both a kit (own eval, ID, outputs, `lib.extendWith`) and a set of embeddable modules that plug into existing evals.
- **Problems solved**, in priority order: composable env overrides; unify wrapped-drv outputs; reusability outside dotfiles.
  Deduplicating the three toolkits' makeWrapper blocks is *not* a stated goal, though it may fall out.
- **Env schema richness**: model the full makeWrapper flag surface.
- **Target shape**: a single wrapped **bin**; input `wrappedBin` is either a path string or a derivation (resolved with `lib.getExe`); package/multi-bin composition is outside.
  `$out` layout follows `binName`: `$out/bin/<binName>` by default, single-file `$out` when `binName = null`.
- **'Result' concept**: the `output` option of the mini-eval run by `mkWrapkitBin`.
- **Inspirations**: the current per-toolkit wrapper blocks; makeWrapper primitives.

## Topics

- (active) `env-override-model` — env submodule type, install sites, module-priority merge, Models A–D, external-profile pluggability.
- (active) `wrapped-drv-generator` — `mkWrapkitBin`, `wrappedBin`/`binName`, `$out` layouts, output construction.
- (active) `wrapper-schema` — full makeWrapper surface, `sep`, flags, process control.
- (active) `packaging-composition` — how a single-bin drv composes into a package.

## Discussion log

- Round 1 — discovery.
  Settled name/slug, scope (both), nature (kit + embeddable), problems, env richness (full surface).
  Kept the override model open: capture Models A, B and C.
- Round 2 — chat sketches.
  Proposed the three models and the concern split (generator vs env-override system).
  User asked to write exploration docs before the spec; chose index-only for now.
- Round 3 — pluggability clarified.
  `profiles.*` is external to wrapkit; wrapkit plugs in via constructors (`mkWrapkitEnvOption`, `mkWrapkitOptions`, `mkWrapkitPkg`).
  Added Model D and moved the profile sketch into The design crux.
- Round 4 — shape converged.
  Renamed `mkWrapkitPkg` to `mkWrapkitBin` (wraps one bin; accepts a path or a package via `lib.getExe`).
  `mkWrapkitBin` runs a small internal module system and returns its `output`; settled the per-action module-priority merge.
- Round 5 — output and schema fixed.
  Output is a single-file drv (`$out` is the executable), built without `replaceBinsInPkg`/`copyFromPkg`.
  Mini-eval is plain `lib.evalModules`; the merge lives inside `mkWrapkitBin`; added the full makeWrapper schema section.
- Round 6 — env schema simplified.
  Added a per-VAR `sep`; `prefix`/`suffix` and variants are now simple string lists reusing it.
- Round 7 — output layout reopened.
  `wrappedBin` settled: accepts a path string or a derivation (`lib.getExe`).
  Doubt raised on `$out`-is-the-executable: the store filename is hash-prefixed and outside `bin/`, so `binName` does not name the command and `PATH`/`lib.getExe` composition breaks.
  Added the "How `output` is built" section with the two candidate layouts; `binName` handling stays open.
- Round 8 — `$out` layout and `binName` settled.
  `binName` is a `mkWrapkitBin` param; a non-null value (default derived from `wrappedBin`) selects `$out/bin/<binName>`, `null` selects the single-file `$out` layout.
  `wrappedBin` accepts both a path string and a derivation (`lib.getExe`).
