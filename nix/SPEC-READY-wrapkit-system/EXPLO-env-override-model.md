# env-override-model — exploration

## Findings

- The env schema is per-toolkit and inconsistent (`{set,set-default}` vs plain `str`).
- Only `set`/`set-default` are modeled; `prefix` and `add-flags` are hand-emitted in each toolkit.
- The system revolves around a reusable **wrapper record**: the schema for one wrapper's whole surface — `env`, `flags`, `argv0`, `chdir`, `run` — in makeWrapper vocabulary.
- That record is *installed* at two kinds of site:
  - at the root of an eval, giving the **commons** (e.g. `config.wrapper.*`);
  - nested under a path, giving an **override** scoped to that consumer (e.g. `config.profiles.foo.wrapper.*`).
- The consumer is called a **result** (`profiles.foo.<result-using-us>`): something that builds a wrapped drv and consumes the effective wrapper record.
- The effective record for a result = commons merged with the result's scoped override.

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
wrapper.env.FOO.set = "hello";                    # the commons
profiles.standalone.wrapper.env.FOO.set = "over"; # this profile's override
profiles.standalone.pkg;                          # drv built from the effective wrapper
```

So a record option at the host root is the commons, one nested under a profile is that profile's override, and `profiles.<name>.pkg` is the wrapped drv built from the effective wrapper.
The host picks the field names; wrapkit only supplies the option.

Wrapkit's pluggability surface is a **function that runs a small module system** and returns its `output`:
- `mkWrapkitWrapperOption { }` — the record option (the full makeWrapper surface: `env`, `flags`, `argv0`, `chdir`, `run`), usable like any other option definition, at any site and under any name.
- `mkWrapkitBin { wrappedBin, ... }` — applies the given wrapper records to a small wrapkit module system and returns its `output` (the wrapped drv).

`mkWrapkitBin` takes the wrapper record in one of two ways:

- **inline mode** — `wrapper = { ... }` written on the call: one definitions record, merged by ordinary module priority;
- **layered mode** — `wrappers = [ <wrapper record> … ]`, an ordered list of already-resolved records (e.g. `config.wrapper` plus a profile's) normalised and then applied one definition apiece.

The rest of the inputs:
- `wrappedBin` — the bin to wrap: either a path string (`"${somepkg}/bin/foo"`) or a derivation, resolved with `lib.getExe`.
- `binName` — the command name; a non-null value (default derived from `wrappedBin`) selects the `$out/bin/<binName>` layout, `null` selects the single-file `$out` layout.

Rough draft:

```nix
mkWrapkitBin =
  { wrappedBin
  , binName ? <derived from wrappedBin>
  , wrapper ? null      # inline mode
  , wrappers ? null     # layered mode
  , ...
  }@args:
  let
    records = if wrappers != null then wrappers else [ wrapper ];
  in
  (lib.evalModules {
    modules = [ ./wrapkit-base.module.nix ]
      ++ map (r: { wrapper = normalise r; }) records;
    specialArgs = { inherit wrappedBin binName; };
  }).config.output;
```

The base module declares `wrapper` (the full surface) and an `output` option; `config.output` builds the drv.
Each record enters as its own definition of the `wrapper` option, so the second module application does the merging: lists concatenate, and a scalar or `sep` set by two records is a genuine conflict the eval rejects.
Inline mode is that same path with a single record, where `lib.mkForce` is available because the record is written as definitions.

The one non-module step is `normalise`, which runs in layered mode only.
A resolved record carries every field, most of them `null` (and `unset = false`), and each of those would register as a definition and collide with another record's real one.
Dropping the null fields before the application leaves only what a layer actually said.

A host then wires the external profile system to it.
The host's `config.wrapper` and `config.profiles.<name>.wrapper` are resolved *values* in the host eval, so they cross the boundary through layered mode:

```nix
profiles.<name>.pkg = mkWrapkitBin {
  wrappedBin = "${pkgs.tmux}/bin/tmux";
  wrappers = [ config.wrapper config.profiles.<name>.wrapper ];
};
```

Because the second application is ordinary module merge, layer *order* decides list order only.
A scalar cannot be overridden by a later layer — precedence is expressed by the action (`setDefault` in the commons, `set` in the profile) — and a same-field clash across layers is an authoring error.

Inline mode is the form for a call that owns its record outright:

```nix
mkWrapkitBin {
  wrappedBin = "foo/tmux";
  wrapper = {
    env.FOO.set = "hello";
  };
};
```

A module *reference* cannot cross that boundary: the module system merges definitions, and offers no way to read an option's definitions back out of a resolved `config.*`.
What crosses is a value, which is why layered mode normalises first instead of merging module references.

## Candidate directions

- **Model A — record option constructor.** Exports a reusable `wrapperType` plus `mkWrapkitWrapperOption`, which returns the record option itself — the shape of any other option definition. _(deferred)_

  ```nix
  wrapperType = ty.submodule {
    options = {
      env = lib.mkOption { type = ty.attrsOf envVarType; default = null; };
      flags = ...; argv0 = ...; chdir = ...; run = ...;
    };
  };

  mkWrapkitWrapperOption = { }: lib.mkOption {
    type = wrapperType;
    default = null;
  };
  ```

  - root: `{ options.wrapper = wrapkit.mkWrapkitWrapperOption { }; }` gives `config.wrapper`.
  - nested: `{ options.profiles.foo.wrapper = wrapkit.mkWrapkitWrapperOption { }; }` gives `config.profiles.foo.wrapper`.
  - The field name is the host's choice: the constructor takes no path, so `{ options.profiles.foo.cfg = wrapkit.mkWrapkitWrapperOption { }; }` is equally valid.
  - Override is implicit in *where* the option is declared; the result merges its site's record over the commons.

- **Model B — global results tree.** A single `wrapkit` option tree; results are first-class and own their override. _(deferred)_

  ```nix
  wrapkit.wrapper = { /* commons wrapperType */ };
  wrapkit.results.<name> = {
    wrapper = { /* wrapperType override, keyed by result name */ };
    package = pkgs.tmux;
    bin = "tmux";
  };
  wrapkit.results.<name>.out  # the resulting wrapped drv
  ```

  - The same `wrapperType` backs `wrapkit.wrapper` and `wrapkit.results.<name>.wrapper`.
  - A profile points at or defines result entries.
  - Override is keyed by the result name.

- **Model C — type + normaliser only.** Wrapkit exports `wrapperType` and the normaliser; nothing is auto-installed. _(deferred)_

  ```nix
  normaliseWrapper = record: /* record minus null fields and `unset = false` */;
  ```

  - Every host installs its own record options, at whatever sites it likes, and runs the same module application itself.
  - Most explicit, least magic; the host repeats the install boilerplate Model A would generate.

- **Model D — `mkWrapkitBin` over a small internal module system (user's current direction).** A function applies wrapper records and returns the eval's `output`. _(active)_

  ```nix
  mkWrapkitBin : { wrappedBin, binName ? <derived>, wrapper ? null, wrappers ? null, ... } -> <derivation>;
  # inline mode: one `wrapper` record; layered mode: `wrappers = [ … ]`
  ```

  - `wrappedBin`: a path string, or a derivation resolved with `lib.getExe`.
  - Two record inputs: inline mode (one `wrapper` record, module priority, `lib.mkForce` available) and layered mode (`wrappers` list, normalised then applied, lists concatenate, scalar clashes error).
  - The mini-eval's base module declares `wrapper` (full makeWrapper surface) and `output`; `config.output` builds the wrapped drv.
  - `profiles.*` stays external; the host calls `mkWrapkitBin` from its own profile config, passing its commons record and the profile's record as values.
  - Open: whether the mini-eval is built with `kitsys` or plain `lib.evalModules`.
  - Models A/B/C remain as alternatives.

## Decisions

- **The record carries the whole wrapper surface** — `env`, `flags`, `argv0`, `chdir`, `run`.
  There are no top-level `env` / `flags` fields on `mkWrapkitBin`. _(settled)_
- **Override merge is per-action** — a record that sets one action leaves the other actions of the same VAR inherited. _(settled)_
- **Lists merge, scalars do not** — every accumulating field concatenates across records in layer order
  (`env.<VAR>.prepend`/`append`/`prependFromFile`/`appendFromFile`, `flags.beforeArgs`/`afterArgs`, `run`).
  A scalar (`env.<VAR>.sep`/`set`/`setDefault`/`unset`, `argv0`, `chdir`) set by two records is a genuine
  conflict and the eval rejects it.
  Precedence comes from the action, not from layer order: `setDefault` in the commons, `set` in the profile. _(settled)_
- **`mkWrapkitBin` takes one of two mutually exclusive record inputs** — inline mode `wrapper = { … }`
  (one definitions record, ordinary module priority, `lib.mkForce` available) and layered mode
  `wrappers = [ … ]` (ordered already-resolved records, normalised, then applied one definition apiece). _(settled)_
- **The schema has no defaults** — `sep`, `unset` and the list fields all default to `null`.
  The effective defaults (`":"`, `false`, `[]`) are applied by the emitter at assembly time, where
  "absent" means "use the default". _(settled)_
- **The normaliser strips nulls** — in layered mode only, every `null` field (and `unset = false`) is dropped
  before the second module application; a resolved record otherwise registers every field as a definition
  and collides with the other records. _(settled)_
- **Values, not module references, cross the eval boundary** — the host holds resolved `config.*` records,
  and the module system cannot read an option's definitions back, so a module-reference input is not available. _(settled)_
- **Layered mode cannot clear or replace** — a later record cannot undo an earlier one's scalar or drop an
  inherited list entry; a replacement story is deferred. _(current; may evolve)_
- **`profiles.*` is external** — wrapkit plugs in via a function that runs its own mini-eval. _(settled)_
- **The mini-eval uses plain `lib.evalModules` for now** — a `kitsys` kit is a later option. _(settled)_

## Open threads

- Does `mkWrapkitWrapperOption` remain a public export for the external profile system to declare its record options?
- Does the commons live at `wrapper.*` or inside a `wrapkit` namespace?
- Is wrapkit's public kit a separate, independent eval from the per-bin mini-evals?
