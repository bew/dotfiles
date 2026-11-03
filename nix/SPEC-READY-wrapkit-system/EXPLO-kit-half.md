# kit-half — exploration

The kit half of wrapkit: how wrapkit is consumed as a kit on `nix/kit-system`, what its
evaluation and module set look like, and whether it ships an opinionated module that declares the
commons, per-profile overrides, and a per-profile wrapped drv.

## Findings

- `SPEC.md` says wrapkit is both a kit (own eval, ID, outputs, `lib.extendWith`) and a set of
  embeddable modules.
- M7's proof in `MILESTONES.md` asks for an ID, outputs, and naming per `nix/kits/README.md`.
- The repo's kits are built with `newToolkit` (`nix/kits/toolkits.nix`) on `kitsys.newKit` /
  `kitsys.defineEval`.
- `newToolkit` requires a `tool`, and bundles `toolkit-base.kit-module.nix` +
  `dir.toolkit-module.nix` + the dynpaths kitsys module + a per-tool base module.
- `kit-modules/toolkit-base.kit-module.nix` declares `ID`, `toolName`, `lib`, `package`,
  `deps.bins`, and the `outputs` submodule; all are tool-oriented, and `ID`/`toolName` have no
  default.
- `kitsys.defineEval` supplies the assertion/warning checks, the `lib` option, and
  `lib.extendWith`; it does not itself require an `ID` or an `outputs` submodule.
- `nix/kits/wrapkit/default.nix` currently exports only `mkWrapkitBin`, `wrapperType`, and
  `mkWrapkitWrapperOption` — no kit, no eval, no module.
- `SPEC.md` states `profiles.*` is external and wrapkit supplies only constructors.
- `wrapkit-base.module.nix` is mini-eval-shaped: it reads `specialArgs.wrappedBin` / `binName` and
  exposes `output`. A kit eval has neither, so the kit needs its own base module and shares only
  `wrapperType` and `mkWrapkitBin` with the mini-eval.
- `kitsys.defineEval` injects only three things: the `lib` option, `assertions` / `warnings`, and
  `config.lib.extendWith` (with the `_kitState` it needs). `ID`, `toolName`, and `outputs` are
  declared by `toolkit-base.kit-module.nix`, not by kitsys — so a kit built on `newKit` gains
  assertions/warnings/extendWith without any ID/outputs obligation.
- `lib.extendWith` needs `_kitState.currentEval`, which only `defineEval` initialises, so extendWith
  is available only through `defineEval`, never through a bare `lib.evalModules`.
- The mini-eval's two current errors are `throw`s: the `wrapper`/`wrappers` mutual exclusion in
  `default.nix`, and the `sep` validation in `wrapper-model.nix`.
- "fyi paths" are the `$out/useful-paths/<name>` symlinks the toolkit bases build for
  introspection: nvimkit passes `fyiExtraDirs` into `makeNvimWrapperPkg` and links each into
  `$out/useful-paths/<name>` (`nvimkit-base.toolkit-module.nix:24-30`, used at `:91-103`);
  tmuxkit links `useful-paths/config` (`tmuxkit-base.toolkit-module.nix:38-39`).
- A toolkit eval is one config instance (`toolConfigs.<name> = toolkits.<toolkit>.eval { … }` in
  `flake.nix`), and one config can carry several wrapped-bin variants: nvimkit exposes
  `outputs.toolPkg.standalone` and `outputs.toolPkg.configured` from one `makeNvimWrapperPkg`.

## Design crux

What is the kit half's module shape, and does an opinionated module that declares `wrapper.*` plus
`profile.*.wrapper.*` plus `profile.*.pkg` belong to wrapkit's own kit, when `SPEC.md` says
`profiles.*` is external and wrapkit supplies only constructors?

## Rejected directions

- **Register wrapkit through `newToolkit`** — requires a `tool` / `toolName` / `ID` and pulls in
  the tool-oriented `outputs` submodule plus the dynpaths and dir modules wrapkit does not use.
- **A preset wrapping the toolkit system** — rejected in favour of a standalone toolkit module.

## Decisions

### (settled) `kit-on-newkit` — the kit half is built on `newKit`

related-to: `topic:env-override-model`

The kit half is built with `kitsys.newKit` / `kitsys.defineEval`, not `newToolkit`. It carries no
`ID`, `toolName`, or tool-shaped `outputs` submodule, so M7 and `SPEC.md` drop that wording and
keep "own eval, `lib.extendWith`, outputs resolve, naming per `nix/kits/README.md`".

### (settled) `profile-scaffold-in-kit` — the toolkit module declares a minimal `profile.*`

related-to: `topic:env-override-model` & `toolkit-module-surface`

The toolkit module declares `profile.*.wrapper` (the per-profile override record) and a placeholder
`profile.*.pkg`. The wrapkit kit itself carries no `profile.*`; profiles belong to the toolkit
module. The implementation is minimal for now.

The real toolkit profile system is defined later and reuses what this module starts. This narrows
`SPEC.md`'s "`profiles.*` is external" to richer profile systems; the toolkit module now seeds a
basic one.

### (settled) `pkg-composes-wrapped-bin` — `profile.*.pkg` composes the wrapped bin

`profile.*.pkg` is a composition (e.g. a `buildEnv`) in which the `mkWrapkitBin` drv is only a
part, so config dirs and other outputs can join it.

### (settled) `toolkit-module-separate` — the kit and the toolkit module are separate artifacts

related-to: `topic:env-override-model`

The wrapkit kit and the toolkit module are separate artifacts. A toolkit config imports the toolkit
module to declare its own bins through the layered wrapper system; the wrapkit kit is a distinct
`newKit` evaluation for standalone use. They share only `wrapperType` and `mkWrapkitBin`.

### (settled) `toolkit-module-location` — the toolkit module lives in `nix/kits/toolkit-modules/`

The toolkit module sits under `nix/kits/toolkit-modules/`, alongside the existing zshkit / nvimkit /
tmuxkit / dir toolkit modules.

### (settled) `toolkit-module-surface` — the toolkit module exposes `wrapper` and `profiles.*`

related-to: `profile-scaffold-in-kit`

The toolkit module declares `wrapper` (the commons record) and `profiles.<name>` with `wrapper`
(the per-profile override), `package`, `binName`, and `pkg` (the composed drv, with `mkWrapkitBin`
inside). A toolkit config writes `wrapper.*` for the commons and `profiles.<name>.wrapper.*` for an
override; the toolkit base reads `profiles.<name>.pkg`.

### (settled) `profiles-only-in-toolkit-module` — `profiles.*` lives only in the toolkit module

related-to: `toolkit-module-surface` & `profile-scaffold-in-kit`

The wrapkit kit carries no `profile.*` options. Profiles belong solely to the toolkit module, which
toolkit configs import; wrapkit's kit surface stays the wrapper record plus `mkWrapkitBin`.

### (settled) `profile-key-free-variant-name` — a profile entry is keyed by a free variant name

related-to: `toolkit-module-surface`

The toolkit base names its profile entries, so one config can carry several wrapped-bin variants
(for example `profiles.standalone` / `profiles.configured`, mirroring nvimkit's two `toolPkg`
outputs). A toolkit config writes `profiles.standalone.wrapper.*` and so on.

### (settled) `fyi-paths-deferred` — per-profile fyi paths are deferred to a migration task

related-to: `toolkit-module-surface`

The kit does not model `$out/useful-paths/<name>` yet; a later migration task resolves what a
profile needs for its fyi links.

### (settled) `single-wrapkit-kit` — one shared kit named `wrapkit`; hosts use `mkWrapkitBin`

related-to: `mini-eval-on-kitsys` & `mkwrapkitbin-returns-config-and-drv`

`nix/kits/wrapkit/` defines a single kit, `wrapkit = kitsys.newKit { … }` — no `Kit` suffix, and no
separate "kit half". `mkWrapkitBin` calls `wrapkit.eval`, passing `wrappedBin` / `binName` through a
per-call `_module.args` module, and the base module reads them as ordinary module args instead of
`specialArgs`. Hosts always go through `mkWrapkitBin` (which returns `{ config; drv; }`); calling
`wrapkit.eval` directly is not part of the public surface.

### (settled) `throws-become-assertions` — the two errors become assertions

related-to: `mini-eval-on-kitsys`

The `wrapper` / `wrappers` mutual exclusion moves inside the eval as an assertion, and the `sep`
validation becomes an assertion too; `checkAssertsAndWarnings` reports both.

### (settled) `mini-eval-on-kitsys` — `mkWrapkitBin`'s mini-eval is built on kitsys

`mkWrapkitBin` runs its mini-eval through `kitsys` (`defineEval`) instead of plain
`lib.evalModules`, so the eval gains `assertions` / `warnings` and `config.lib.extendWith`. The
cost is the `../kit-system` sibling import; no `ID` / `toolName` / `outputs` obligation follows.

### (settled) `mkwrapkitbin-returns-config-and-drv` — `mkWrapkitBin` returns `{ config; drv; }`

`mkWrapkitBin` returns an attrset with the evaluated config at `config` and the wrapped derivation
at `drv`. Every call site — `profile.*.pkg` and the tests — reads `.drv`.

### (settled) `extendwith-refines-built-config` — `lib.extendWith` lets a host refine a built config

related-to: `mini-eval-on-kitsys` & `mkwrapkitbin-returns-config-and-drv`

A host holds the evaluated config from `mkWrapkitBin` and layers module-priority definitions on top
with `config.lib.extendWith` (`mkForce` and friends), then reads the refined `.drv`. This is the
concrete use that justifies exposing the config.

### (settled) `kit-eval-class` — the kit's `defineEval` uses `class = "wrapkit"`

related-to: `single-wrapkit-kit`

The kit's `defineEval` passes `class = "wrapkit"`.

### (settled) `kit-eval-location` — the kit's evaluation lives beside the helpers

related-to: `single-wrapkit-kit`

The `wrapkit = kitsys.newKit { … }` definition lives in `nix/kits/wrapkit/`, beside
`wrapper-model.nix` and `wrapper-composer.nix`.

### (settled) `wraplib-folded-into-m7` — `wraplib` ships with the kit milestone

related-to: `single-wrapkit-kit`, `wraplib-export-site`, `wraplib-helpers-only`

The `wraplib` output — the helper functions — is delivered inside the kit-half milestone (M7). The
standalone flake and its remaining output naming are dropped.

### (settled) `wraplib-export-site` — `wraplib` is a `nix/kits/wrapkit` export

related-to: `wraplib-folded-into-m7`

`wraplib` is exposed from `nix/kits/wrapkit/default.nix` only; there is no flake wiring.

### (settled) `wraplib-helpers-only` — `wraplib` is the helper functions, with no module export

related-to: `single-wrapkit-kit`, `embeddable-via-option-constructor`

`wraplib` holds the helper functions only — `mkWrapkitBin`, `wrapperType`, `mkWrapkitWrapperOption`.
No module is exported: `wrapkit-base.module.nix` is an implementation detail of `mkWrapkitBin`, since
a host builds bins through `mkWrapkitBin` and never calls the eval directly.

### (settled) `embeddable-via-option-constructor` — the embeddable half is the option constructor

related-to: `wraplib-helpers-only`

wrapkit's embeddable capability is `mkWrapkitWrapperOption` — it returns the record-option module a
host embeds at a chosen site — plus `wrapperType`. There is no embeddable module file.
