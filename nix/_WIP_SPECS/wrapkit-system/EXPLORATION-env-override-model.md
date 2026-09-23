# env-override-model — exploration

## Findings

- The env schema is per-toolkit and inconsistent (`{set,set-default}` vs plain `str`).
- Only `set`/`set-default` are modeled; `prefix` and `add-flags` are hand-emitted in each toolkit.
- The env-override system revolves around a reusable **env submodule type**: the schema for "what to do to the environment" in makeWrapper vocabulary.
- That type is *installed* at two kinds of site:
  - at the root of an eval, giving `config.env.*` — the **commons**;
  - nested under a path, giving e.g. `config.profiles.foo.env.*` — an **override** scoped to that consumer.
- The consumer is called a **result** (`profiles.foo.<result-using-us>`): something that builds a wrapped drv and consumes the effective env.
- The effective env for a result = commons merged with the result's scoped override.

## Design crux

The problem has two parts that are usually entangled, and should be split in the spec.
The wrapped-drv generator turns a (package, bin, env/arg spec) into a `makeWrapper` drv.
The env-override module system composes the env/arg spec from a commons plus scoped overrides.

What remains genuinely open:
- what a result *is*, concretely;
- whether an override is keyed by the result's name (global tree) or is implicit in the install site.

### Profiles are external

The profile system is a separate, future concept that wrapkit plugs into; wrapkit does not define `profiles.*`.
The profile system's shape, as sketched by the user:

```nix
env.FOO.set = "hello";
profiles.standalone.env.FOO.set = "over"; # override!
profiles.standalone.pkg;                   # drv that uses FOO=over
```

So `env` at the host root is the commons, `profiles.<name>.env` is the per-profile override, and `profiles.<name>.pkg` is the wrapped drv built from the effective env.

Wrapkit's pluggability surface is a **function that runs a small module system** and returns its `output`:
- `mkWrapkitEnvOption {}` — the env option schema (full makeWrapper surface), usable standalone.
- `mkWrapkitBin { bin, modules, ... }` — evaluates a small wrapkit module system with `modules`, and returns its `output` (the wrapped drv).

`mkWrapkitBin` inputs:
- `wrappedBin` — the bin to wrap: either a path string (`"${somepkg}/bin/foo"`) or a derivation, resolved with `lib.getExe`.
- `binName` — the command name; a non-null value (default derived from `wrappedBin`) selects the `$out/bin/<binName>` layout, `null` selects the single-file `$out` layout.
- `modules` — the small module system: the modules to merge (toolkit defaults, commons, overrides).

Rough draft:

```nix
mkWrapkitBin = { wrappedBin, binName ? <derived from wrappedBin>, modules ? [], specialArgs ? {} }:
  (lib.evalModules {
    modules = [ ./wrapkit-base.module.nix ] ++ modules;
    specialArgs = { inherit wrappedBin binName; } // specialArgs;
  }).config.output;
```

The base module declares `env` (full surface) and an `output` option; `config.output` builds the drv.
All env merging happens inside this eval, so the returned drv already reflects commons plus overrides.

A host then wires the external profile system to it:

```nix
profiles.<name>.pkg = mkWrapkitBin {
  wrappedBin = "${pkgs.tmux}/bin/tmux";
  modules = [ commonsModule { env = config.profiles.<name>.env; } ];
};
```

## Candidate directions

- **Model A — install helper.** Exports a reusable `envType` plus `mkEnvInstall`, which returns a module placing the `env` option at an attr-path. _(deferred)_

  ```nix
  envType = ty.submodule {
    options = {
      set = lib.mkOption { type = ty.nullOr ty.str; default = null; };
      set-default = lib.mkOption { type = ty.nullOr ty.str; default = null; };
      # ... full makeWrapper surface
    };
  };

  mkEnvInstall = { path ? [] }: {
    options = lib.setAttrByPath (path ++ [ "env" ]) (lib.mkOption {
      type = envType;
      default = {};
    });
  };
  ```

  - root install: `imports = [ (wrapkit.mkEnvInstall {}) ];` gives `env.*`.
  - nested install: `imports = [ (wrapkit.mkEnvInstall { path = [ "profiles" "foo" ]; }) ];` gives `profiles.foo.env.*`.
  - Override is implicit in *where* the module is installed; the result merges its site's `env` over the commons.

- **Model B — global results tree.** A single `wrapkit` option tree; results are first-class and own their override. _(deferred)_

  ```nix
  wrapkit.env = { /* commons envType */ };
  wrapkit.results.<name> = {
    env = { /* envType override, keyed by result name */ };
    package = pkgs.tmux;
    bin = "tmux";
    # ... wrapper args spec
  };
  wrapkit.results.<name>.out  # the resulting wrapped drv
  ```

  - The same `envType` backs `wrapkit.env` and `wrapkit.results.<name>.env`.
  - A profile points at or defines result entries.
  - Override is keyed by the result name.

- **Model C — type + resolver only.** Wrapkit exports `envType` and `resolveEnv commons overrides`; nothing is auto-installed. _(deferred)_

  ```nix
  resolveEnv = commons: overrides: /* merged env spec */;
  ```

  - Every host declares its own `env` / `profiles.foo.env` options and calls the resolver.
  - Most explicit, least magic; the host repeats the install boilerplate Model A would generate.

- **Model D — `mkWrapkitBin` over a small internal module system (user's current direction).** A function runs its own mini-eval and returns the eval's `output`. _(active)_

  ```nix
  mkWrapkitBin : { wrappedBin, binName ? <derived>, modules ? [], specialArgs ? {} } -> <derivation>;
  ```

  - `wrappedBin`: a path string, or a derivation resolved with `lib.getExe`.
  - `modules`: the small module system whose `env` definitions the eval merges.
  - The mini-eval's base module declares `env` (full makeWrapper surface) and `output`; `config.output` builds the wrapped drv.
  - `profiles.*` stays external; the host calls `mkWrapkitBin` from its own profile config.
  - Open: whether the mini-eval is built with `kitsys` or plain `lib.evalModules`.
  - Models A/B/C remain as alternatives.

## Decisions

- **Override merge uses module priority, per-action** — an override VAR that sets one action (e.g. `set`) leaves the commons' other actions (e.g. `prefix`) inherited. _(settled)_
- **`profiles.*` is external** — wrapkit plugs in via a function that runs its own mini-eval. _(settled)_
- **The mini-eval uses plain `lib.evalModules` for now** — a `kitsys` kit is a later option. _(settled)_
- **The merge happens inside `mkWrapkitBin`** — the caller passes commons and override as separate modules. _(settled)_

## Open threads

- Does `mkWrapkitEnvOption` remain a public export for the external profile system to declare its `env`/`profiles.<name>.env` options?
- Does the commons live at the eval root (`env.*`) or inside a `wrapkit` namespace?
- Is wrapkit's public kit a separate, independent eval from the per-bin mini-evals?
