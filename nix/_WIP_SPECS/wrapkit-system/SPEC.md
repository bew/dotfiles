# [DRAFT] wrapkit-system

> IMPORTANT: Before any drafting/planning/editing of this spec,
> agents MUST load one of the spec-writing skill first.

## Introduction

wrapkit-system is a module system that turns a binary into a `makeWrapper`-wrapped derivation, plus a composable environment-override layer on top of it.

The motivation comes from the dotfiles repo.
Binaries are wrapped today once per toolkit: `nix/kits/toolkit-modules/tmuxkit-base.toolkit-module.nix`, `zshkit-base.toolkit-module.nix`, and `nvimkit-base.toolkit-module.nix`.
Each hand-rolls a `makeWrapper` invocation inside its `outputs.toolPkg.standalone`, and shares only the low-level `mypkglib.replaceBinsInPkg` helper (`nix/mypkglib.nix`).
The results have drifted: the `env` option is `{set, set-default}` for tmuxkit, a plain `attrsOf str` for nvimkit, and absent for zshkit; only nvimkit exposes a second result variant (`toolPkg.configured`); `prefix` and `add-flags` are hand-emitted rather than modeled.

wrapkit-system addresses these problems, in priority order:
- composable environment overrides, so a shared default can be overridden per consumer;
- unified wrapped-drv outputs, so every tool produces the same shape;
- reusability outside dotfiles, so the same system can be consumed as a standalone flake.

Deduplicating the toolkits' makeWrapper blocks is *not* a stated goal, though it may fall out of the unification.

The system is simultaneously a **kit** (its own evaluation, IDs, outputs, and `lib.extendWith` support) and a set of **embeddable modules** that plug into existing evaluations.
The kit half makes wrapkit usable standalone and composable with the repo's other kits; the embeddable half lets a host evaluation (a toolkit, a home, a profile system) declare an `env` option at a chosen site and build wrapped bins from it.

Use-cases the design must serve:
- a toolkit builds its wrapped bin from shared defaults plus tool-specific wrapper arguments;
- a user overrides an env variable for one consumer without touching the shared default;
- a host outside dotfiles reuses wrapkit through a standalone flake;
- the same wrapped bin is emitted in either the conventional `$out/bin/<binName>` layout or a single-file `$out` layout.

The design is inspired by the existing per-toolkit wrapper blocks and by the `makeWrapper` primitives themselves, which are the vocabulary the wrapper schema models.
It follows the repo's prior art for a module exportable in several variants at once: the `dynpaths` flake, which exposes `modules.generic.dynpaths`, `modules.homeManager.dynpathsChecker`, and `modules.kitsys.dynpaths` from one source.
It is also informed by the sibling draft `nix/_WIP_SPECS/hm-toolconfigs-integration-CRAZY!/SPEC.md`, which proposes recomputing a tool config's outputs against per-home config via `lib.extendWith`.

## Naming & IDs

Canonical names for the concepts this spec introduces (kept here until and unless a Terminology & Key Concepts section is added — see Global Open Questions):
- **wrapped bin** — the single binary derivation wrapkit produces; `$out` is either `$out/bin/<binName>` or the executable file itself.
- **`wrappedBin`** — the input binary to wrap: a path string (`"${somepkg}/bin/foo"`) or a derivation, resolved with `lib.getExe`.
- **`binName`** — the command name; a string selects the `$out/bin/<binName>` layout, `null` selects the single-file `$out` layout.
- **commons** — the `env` option installed at the root of an evaluation, shared by every consumer of that evaluation.
- **override** — an `env` option installed at a nested site, scoped to the consumer at that site.
- **result** — a consumer that builds a wrapped bin and consumes the effective env.
- **effective env** — the commons merged with a result's override, per-action.
- **mini-eval** — the small `lib.evalModules` invocation run by `mkWrapkitBin`, whose `output` is the wrapped bin.
- **wrapper schema** — the typed model of the full `makeWrapper` surface (env actions, flags, process control).
- **wrapper arguments** — the `makeWrapper` argument list assembled from the effective env, flags, and process control.

Identifier patterns:
- Constructor/function names use the `mkWrapkit*` prefix: `mkWrapkitBin` (active), `mkWrapkitEnvOption` and `mkWrapkitPkg` (proposed, unresolved).
- The base module file is `wrapkit-base.module.nix`, loaded first into every mini-eval.
- Option paths in the base module: `env.<VAR>.<action>`, `flags.<action>`, `argv0`, `chdir`, `run`, plus the read-only `output`.
- `<VAR>` is a free-form environment-variable name string; wrapkit assigns no structure to it.
- Result names are owned by the external profile system (`profiles.<name>`); wrapkit does not name results.
- Toolkit and tool-config IDs follow the existing `nix/kits/README.md` conventions and are external to wrapkit.

### Open Questions

1. Is the standalone flake placed in the floated `nix/thing-wrapper-flake/` directory, or somewhere else — and what is its output naming?
   Non-blocking. The directory does not exist yet; the name was floated in the original request, not settled.

## Interface / How to use

### `mkWrapkitBin`

The primary entry point runs a mini-eval and returns its `output`:

```nix
mkWrapkitBin = {
  wrappedBin,
  binName ? <derived from wrappedBin>,
  modules ? [],
  specialArgs ? {},
}: <derivation>;

# equivalent to:
mkWrapkitBin = { wrappedBin, binName ? <derived>, modules ? [], specialArgs ? {} }:
  (lib.evalModules {
    modules = [ ./wrapkit-base.module.nix ] ++ modules;
    specialArgs = { inherit wrappedBin binName; } // specialArgs;
  }).config.output;
```

- `wrappedBin` — the binary to wrap: a path string (`"${somepkg}/bin/foo"`) or a derivation, resolved with `lib.getExe`.
- `binName` — the command name; defaults to a name derived from `wrappedBin`.
  A non-null value selects the `$out/bin/<binName>` layout; `null` selects the single-file `$out` layout.
- `modules` — the modules whose `env`, `flags`, and process-control definitions the mini-eval merges.
  Callers pass the commons and each override as separate modules; priority does the merging.
- `specialArgs` — extra values threaded into the mini-eval (the base module injects `wrappedBin` and `binName`).

A complete, non-toy wiring for tmux, with a shared default and a per-result override:

```nix
wrapkit = import ./wrapkit; # or a flake output

entrypoint = "/nix/store/…/tmux.conf";

tmuxWrapped = wrapkit.mkWrapkitBin {
  wrappedBin = "${pkgs.tmux}/bin/tmux";
  binName = "tmux";
  modules = [
    # commons: shared defaults
    {
      env.TMUX_CONFIG_ENTRYPOINT.set = entrypoint;
      env.TERMINFO_DIRS.prefix = [ "${pkgs.tmux.terminfo}/share/terminfo" ];
      env.TMUX_PLUGIN_RESURRECT_PATH.set = "${resurrect}/share/tmux-plugins/resurrect";
      flags.add-flags = [ "-f" entrypoint ];
    }
    # per-result override: higher module priority
    {
      env.TMUX_CONFIG_ENTRYPOINT.set = "over"; # only `set` is overridden; other commons actions survive
      flags.append-flags = [ "-d" ];
    }
  ];
};
```

### The `env` option

`env` is keyed by environment-variable name; each value is a submodule of actions.
Every action maps to a `makeWrapper` flag (see Wrapper schema for the authoritative mapping).

```nix
env.FOO = {
  sep = ":";                                # shared separator for the prefix/suffix variants (default ":")
  set = "hello";                            # --set FOO hello
  set-default = "fallback";                 # --set-default FOO fallback
  unset = false;                            # --unset FOO
  prefix = [ "/a" "/b" ];                   # --prefix FOO : /a:/b
  suffix = [ "/c" ];                        # --suffix FOO : /c
  prefix-each = [ "/d" "/e" ];              # one --prefix-each FOO : <val> per element
  suffix-each = [ "/f" ];                   # one --suffix-each FOO : <val> per element
  prefix-contents = [ ./extra-paths ];      # --prefix-contents FOO : <file>
  suffix-contents = [ ./more-paths ];       # --suffix-contents FOO : <file>
};
```

`prefix`/`suffix` and their variants are lists of strings joined by the VAR's `sep`; the `-contents` variants take file paths.

### The `flags` option

`flags` models the args passed to the wrapped program itself.

```nix
flags.add-flags = [ "--config" cfg ];   # --add-flags, verbatim (shell-interpreted)
flags.append-flags = [ "-d" ];          # --append-flags, verbatim
flags.add-flag = [ "--foo" ];           # --add-flag, single arg (shell-quoted)
flags.append-flag = [ "--bar" ];        # --append-flag, single arg (shell-quoted)
```

### Process control

Process-control options live at the top level of the module:

```nix
argv0 = null;     # null → no flag; "inherit" → --inherit-argv0; "resolve" → --resolve-argv0; <str> → --argv0 <str>
chdir = null;     # null → no flag; <str> → --chdir <str>
run = [ ];        # --run <cmd> per element
```

### Wiring the external profile system

`profiles.*` is external; wrapkit only supplies the constructor.
A host declares `env` at the root (commons) and under each profile (override), then calls `mkWrapkitBin` with commons and override as separate modules:

```nix
env.TMUX_CONFIG_ENTRYPOINT.set = "hello";

profiles.standalone.env.TMUX_CONFIG_ENTRYPOINT.set = "over"; # override!

profiles.standalone.pkg = wrapkit.mkWrapkitBin {
  wrappedBin = "${pkgs.tmux}/bin/tmux";
  modules = [
    { env = config.env; }
    { env = config.profiles.standalone.env; }
  ];
};
```

The host owns the `env` and `profiles.<name>.env` option declarations; wrapkit's pluggability surface is the constructor, not the options themselves.
How to declare those options is unresolved — see Environment override model.

### Open Questions

1. How does a host pass an already-resolved override value (`config.profiles.<name>.env`) without its materialized defaults clobbering commons actions it does not set?
   Non-blocking. Per-action inheritance works when the override module defines only what it sets; a resolved value carries defaults for the rest, so the mapping needs a mechanism (e.g. a sentinel, `mkForce`, or a `mkWrapkitEnvOption`-provided adapter module) to stay per-action.
2. Does `mkWrapkitBin` also take a target bin name independent of `binName` (nvim uses a dynamic `NVIM_APPNAME` as both command name and env)?
   Non-blocking. `binName` currently serves both roles; nvim's dual use suggests they may need to be separable.

## Environment override model

The env-override system revolves around one reusable **env submodule type**: the typed schema of "what to do to the environment" in `makeWrapper` vocabulary.
The same type backs every install site:

- at the root of an evaluation it yields `config.env.*` — the **commons**;
- nested under a path it yields e.g. `config.profiles.foo.env.*` — an **override** scoped to the consumer at that site.

The consumer is a **result** (`profiles.foo.<result-using-us>`): something that builds a wrapped bin and consumes the effective env.
The **effective env** for a result is the commons merged with the result's scoped override.

Merging uses **module priority, per action**.
An override that sets one action for a VAR (e.g. `env.FOO.set`) leaves the commons' other actions for that VAR (e.g. `env.FOO.prefix`) inherited.
This is what makes overrides composable rather than wholesale replacements.

The merge happens **inside `mkWrapkitBin`**.
The caller passes the commons and each override as separate modules; the mini-eval's normal module merge does the rest, so precedence is expressed by module order/priority rather than by an explicit merge function.

The mini-eval uses plain `lib.evalModules` for now; building it on `kitsys` is a later option (see Design options).

`profiles.*` is not defined by wrapkit.
The profile system is a separate, future concept that wrapkit plugs into via the `mkWrapkitBin` constructor, as sketched in Interface / How to use.

### Open Questions

1. Does `mkWrapkitEnvOption` remain a public export, so an external profile system can declare its `env` / `profiles.<name>.env` options from the same type?
   Non-blocking. Public export favors reusability (a stated goal); keeping it internal favors a smaller surface.
2. Does the commons live at the evaluation root (`env.*`) or inside a `wrapkit` namespace (`wrapkit.env.*`)?
   Non-blocking. Root `env.*` is the user's sketch and reads well; a namespace avoids collisions if a host already uses `env`.
3. Is wrapkit's public kit a separate, independent evaluation from the per-bin mini-evals, or the same evaluation machinery exposed twice?
   Non-blocking. Affects how the "kit" half of the nature is built; both halves share the same base module and schema regardless.

## Wrapper schema

The wrapper schema is the typed model of the full `makeWrapper` surface, so every wrapper argument a toolkit hand-emits today becomes expressible data.
Mapping to `makeWrapper` flags (source: `pkgs/build-support/setup-hooks/make-wrapper.sh`):

Environment variables, keyed by `VAR` under `env`:
- `sep` (`str`, default `":"`) — the shared separator reused by every prefix/suffix variant for this VAR; not itself a flag.
- `set` (`nullOr str`, default `null`) → `--set VAR VAL`.
- `set-default` (`nullOr str`, default `null`) → `--set-default VAR VAL`.
- `unset` (`bool`, default `false`) → `--unset VAR`.
- `prefix` / `suffix` (`listOf str`) → one `--prefix` / `--suffix VAR <sep> VAL`, with the list joined by `sep`.
- `prefix-each` / `suffix-each` (`listOf str`) → one `--prefix-each` / `--suffix-each VAR <sep> VAL` per element.
- `prefix-contents` / `suffix-contents` (`listOf path`) → the `--prefix-contents` / `--suffix-contents VAR <sep> FILE` variants.

Flags for the wrapped invocation, under `flags`:
- `add-flags` / `append-flags` (`listOf str`) — verbatim, shell-interpreted → `--add-flags` / `--append-flags`.
- `add-flag` / `append-flag` (`listOf str`) — single arg, shell-quoted → `--add-flag` / `--append-flag`.

Process control, top-level:
- `argv0` (`null | "inherit" | "resolve" | str`, default `null`) → no flag / `--inherit-argv0` / `--resolve-argv0` / `--argv0 NAME`.
- `chdir` (`nullOr str`, default `null`) → `--chdir DIR`.
- `run` (`listOf str`, default `[ ]`) → `--run COMMAND` per element.

Schema notes:
- A per-VAR `sep` avoids repeating the separator across the prefix/suffix variants.
- `--prefix` treats its VAL as one de-duplicated, order-preserving unit, while `--prefix-each` emits one operation per element; the schema preserves that distinction.
- `--add-flag` and `--add-flags` differ only in shell quoting (single arg vs verbatim), so the schema keeps them distinct.
- The per-action model is what lets an override set `env.FOO.set` while inheriting a commons `env.FOO.prefix`.

### Open Questions

1. Is `env.<VAR>` a per-VAR action submodule, or an ordered list of action entries applied in order?
   Non-blocking. The per-VAR submodule (with `sep`) is the active direction; an ordered list would give explicit ordering but lose the typed per-action override merge.

## Output construction & layouts

`output` is a read-only package option built from the effective env, flags, and process control.
The base module assembles the **wrapper arguments** (one `makeWrapper` argument list) from those definitions, then builds the wrapped bin.
The builder never uses `replaceBinsInPkg`/`copyFromPkg`, because it generates a single binary rather than copying a package.

The layout is selected by `binName`.

Layout 2 (default) — `$out/bin/<binName>`:

```nix
output = runCommandLocal (binName or "wrapped-bin") { nativeBuildInputs = [ makeWrapper ]; } ''
  mkdir -p $out/bin
  makeWrapper ${wrappedBin} $out/bin/${binName} ${lib.escapeShellArgs wrapperArgs}
'';
```

Layout 1 — `$out` is the executable file, opted into with `binName = null`:

```nix
output = runCommandLocal "wrapped-bin" { nativeBuildInputs = [ makeWrapper ]; } ''
  makeWrapper ${wrappedBin} $out ${lib.escapeShellArgs wrapperArgs}
'';
```

Layout tradeoff:
- Layout 2 keeps `binName` effective as the command name, composes into `PATH` environments (e.g. `home.packages` / `buildEnv`), and resolves via `lib.getExe`.
- Layout 1 is minimal (one file), but the executable's on-disk name is the hash-prefixed derivation name and it lives outside any `bin/`, so it cannot be added to `PATH` and `lib.getExe` does not resolve it.

### Open Questions

1. How is the default `binName` derived from `wrappedBin` when not given (basename of a path string; `pname`/`name` of a derivation)?
   Non-blocking. The exact rule is mechanical; both layouts' validity is unaffected.

## Placement / Scope

wrapkit-system is delivered as both a **kit** and a set of **embeddable modules**.
The kit half makes it usable standalone and composable with the repo's other kits (`lib.extendWith` support, IDs, outputs).
The embeddable half supplies the base module and the `env` type that a host can install at chosen sites.

Where things may be defined:
- the **commons** at the root of a host evaluation (`config.env.*`);
- an **override** at a nested site (`config.profiles.<name>.env.*`);
- the **wrapper definitions** (`flags`, process control, and the effective env) inside the modules passed to `mkWrapkitBin`.

What wrapkit does and does not own:
- wrapkit **does** own the env submodule type, the base module, the wrapper-argument assembly, and the `mkWrapkitBin` constructor.
- wrapkit **does not** define `profiles.*`; the profile system is external.
- wrapkit's target is a **single bin**; package/multi-bin composition (bins plus config dirs) is outside it.

### Open Questions

1. How is the single-bin drv composed into a package (bins + config dirs) — a separate `mkWrapkitPkg`, or each toolkit's job?
   Non-blocking. The single-bin target is settled; composition is explicitly out of scope and may become a separate constructor later.

## Env override as module priority (`<Feature>` as `<Primitive>`)

The familiar feature — "install an env default at a root and let a consumer override it" — maps onto the Nix module primitive rather than onto a bespoke merge mechanism.

Mapping:
- "the commons" ↔ an `env` option definition at the evaluation root.
- "an override scoped to a consumer" ↔ an `env` option definition at that consumer's site (a nested attr-path, e.g. `profiles.foo`).
- "the override wins" ↔ module priority: the override is a module ordered after (or forced above) the commons.
- "an override touches one action but not the rest" ↔ two modules defining different sub-options of the same VAR; the module merge keeps both.

Because the whole override story is just module definitions at different sites, the same env submodule type serves both halves with no special object for "an override".

The install itself is an `imports` entry that places the `env` option at a chosen attr-path:

```nix
# root install → config.env.*
imports = [ (wrapkit.mkWrapkitEnvOption {}) ];

# nested install → config.profiles.foo.env.*
imports = [ (wrapkit.mkWrapkitEnvOption { path = [ "profiles" "foo" ]; }) ];
```

Whether `mkWrapkitEnvOption` ships as a public install helper, or the host declares these options itself, is unresolved — see Environment override model.

## Design options

Localized alternatives within the chosen direction.

**Output layout** — Layout 2 (default) vs Layout 1.
Decision criteria: use Layout 2 whenever the bin must compose into `PATH`, `buildEnv`, `home.packages`, or resolve via `lib.getExe`; use Layout 1 only when a single self-contained executable file is wanted and PATH composition is irrelevant.

**Env schema shape** — per-VAR action submodule (active) vs ordered action list (deferred).
Decision criteria: use the per-VAR submodule when typed, per-action override merging matters (the composability goal); use an ordered list when explicit operation ordering is required and wholesale replacement is acceptable.
The per-VAR form loses strict ordering of operations within one VAR; the ordered form loses the typed per-action merge.

**Mini-eval substrate** — plain `lib.evalModules` (active) vs a `kitsys` kit (later option).
Decision criteria: use plain `lib.evalModules` for the per-bin mini-evals to keep them small and dependency-free; move to `kitsys` if the kit half needs `lib.extendWith`, IDs, or outputs shared with the mini-evals.

## Alternatives & Tradeoffs

Whole-direction alternatives considered during discovery.

**Model A — install helper.**

```nix
mkEnvInstall = { path ? [] }: {
  options = lib.setAttrByPath (path ++ [ "env" ]) (lib.mkOption { type = envType; default = {}; });
};
# root: imports = [ (mkEnvInstall {}) ];
# nested: imports = [ (mkEnvInstall { path = [ "profiles" "foo" ]; }) ];
```

- Advantages: minimal; the override is implicit in where the module is installed; no results registry.
- Costs: the host still calls the wrapped-drv generator itself; the env-install and drv-generation halves stay separate.

**Model B — global results tree.**

```nix
wrapkit.env = { /* commons envType */ };
wrapkit.results.<name> = { env = { /* override */ }; package = pkgs.tmux; bin = "tmux"; };
wrapkit.results.<name>.out; # the wrapped drv
```

- Advantages: results are first-class, keyed by name; one tree to inspect.
- Costs: a results registry and naming scheme wrapkit does not otherwise need; couples the generator to the tree.

**Model C — type + resolver only.**

```nix
resolveEnv = commons: overrides: /* merged env spec */;
```

- Advantages: most explicit; no magic; nothing auto-installed.
- Costs: every host repeats the install boilerplate; no shared constructor for the drv.

**Model D — `mkWrapkitBin` over a small internal module system (active).**

```nix
mkWrapkitBin : { wrappedBin, binName ? <derived>, modules ? [], specialArgs ? {} } -> <derivation>;
```

- Advantages: one constructor does both halves; the merge is ordinary module merge; the host stays free to keep `profiles.*` external.
- Costs: a mini-eval per bin; the caller must pass commons and overrides as modules (and see the resolved-value caveat in Interface / How to use).

**Decision criteria**: choose Model D when a single constructor and module-priority composability are wanted and a mini-eval per bin is acceptable; Model A when env install and drv generation should be kept apart; Model B when the host needs a named results registry; Model C when minimal machinery and full host control win over reuse.

Models A/B/C were deferred in favor of D, not rejected outright.

## Related artifacts

- `nix/_WIP_SPECS/wrapkit-system/EXPLORATION-*.md` — the exploration docs (`BRIEF`, `env-override-model`, `wrapped-drv-generator`, `wrapper-schema`, `packaging-composition`) that feed this spec, including the full discussion log.
- `nix/mypkglib.nix` — the current shared wrapped-pkg builder (`replaceBinsInPkg`); wrapkit replaces it for the single-bin case.
- `nix/kits/toolkit-modules/{tmuxkit,zshkit,nvimkit}-base.toolkit-module.nix` — the current per-toolkit wrapper blocks whose drift this spec unifies.
- `pkgs/build-support/setup-hooks/make-wrapper.sh` in nixpkgs — the primitives the wrapper schema models.
- the `dynpaths` flake (`github:bew/nix-dynpaths`) — prior art for exporting one module in several variants (`generic`, `homeManager`, `kitsys`).
- `nix/_WIP_SPECS/hm-toolconfigs-integration-CRAZY!/SPEC.md` — sibling draft proposing per-home output recomputation via `lib.extendWith`; informs the result/outputs API.
- `nix/DESIGN_config_system.md` — the Kit/Module/Preset/Profile/Config vocabulary wrapkit's "kit + embeddable modules" nature fits into.

## Global Open Questions

**Terminology & Key Concepts** (TKC) — Whether this section is needed for this spec.
Non-blocking. Refer to spec-writing skill for guidance.

**Adoption scope** — Is migrating the three existing toolkits onto wrapkit in scope, or is this spec limited to designing the system?
Non-blocking. The system is designed for reuse, but the spec describes wrapkit itself, not a migration plan.