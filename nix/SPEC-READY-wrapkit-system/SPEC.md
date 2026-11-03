# [READY] wrapkit-system

## Introduction

wrapkit-system is a module system that turns a binary into a `makeWrapper`-wrapped derivation, plus a composable environment-override layer on top of it.

The motivation comes from the dotfiles repo.
Binaries are wrapped today once per toolkit: `nix/kits/toolkit-modules/tmuxkit-base.toolkit-module.nix`, `zshkit-base.toolkit-module.nix`, and `nvimkit-base.toolkit-module.nix`.
Each hand-rolls a `makeWrapper` invocation inside its `outputs.toolPkg.standalone`, and shares only the low-level `mypkglib.replaceBinsInPkg` helper (`nix/mypkglib.nix`).
The results have drifted: the `env` option is `{set, set-default}` for tmuxkit, a plain `attrsOf str` for nvimkit, and absent for zshkit; only nvimkit exposes a second result variant (`toolPkg.configured`); `prepend` and `beforeArgs` are hand-emitted rather than modeled.

wrapkit-system addresses these problems, in priority order:
- composable environment overrides, so a shared default can be overridden per consumer;
- unified wrapped-drv outputs, so every tool produces the same shape;
- reusability outside dotfiles, so the same system can be consumed through the `wraplib` export.

Deduplicating the toolkits' makeWrapper blocks is *not* a stated goal, though it may fall out of the unification.

The system is simultaneously a **kit** (its own evaluation and `lib.extendWith` support) and a set of **embeddable helpers** for host evaluations.
The kit half makes it usable standalone and composable with the repo's other kits; the helpers let a host evaluation (a toolkit, a home, a profile system) declare a record option at a chosen site and build wrapped bins from it.

Use-cases the design must serve:
- a toolkit builds its wrapped bin from shared defaults plus tool-specific wrapper arguments;
- a user overrides an env variable for one consumer without touching the shared default;
- a host outside dotfiles reuses wrapkit through the `wraplib` export;
- the same wrapped bin is emitted in either the conventional `$out/bin/<binName>` layout or a single-file `$out` layout.

The design is inspired by the existing per-toolkit wrapper blocks and by the `makeWrapper` primitives themselves, which are the vocabulary the wrapper schema models.
The kit half builds on the repo's kit system (`nix/kit-system`), the substrate the repo's other kits share.
It is also informed by the sibling draft `nix/SPEC-DRAFT-hm-toolconfigs-integration-CRAZY!/SPEC.md`, which proposes recomputing a tool config's outputs against per-home config via `lib.extendWith`.

## Terminology & Key Concepts

Terms this spec introduces, defined here in the sense the spec uses them.

**wrapped bin** (new!):
The single binary derivation wrapkit produces.
Its `$out` is either `$out/bin/<binName>` or the executable file itself.

**`wrappedBin`** (new!):
The input binary to wrap: a path string (`"${somepkg}/bin/foo"`) or a derivation, resolved with `lib.getExe`.

**`binName`** (new!):
The command name.
A string selects the `$out/bin/<binName>` layout; `null` selects the single-file `$out` layout.
It is the sole naming input; there is no separate target-name field.

**wrapper record** (new!):
The schema for one wrapper's whole surface: `env`, `flags`, `argv0`, `chdir`, `run`.

**record option** (new!):
An option a host installs from wrapkit's schema, holding a wrapper record.
Its site and field name are the host's choice: wrapkit fixes the record type, not where it lives.

**commons** (new!):
A record option installed at the root of an evaluation, shared by every consumer of that evaluation.

**override** (new!):
A record option installed at a nested site, scoped to the consumer at that site.

**result** (new!):
A consumer that builds a wrapped bin and consumes the effective wrapper.

**effective wrapper** (new!):
The commons merged with a result's override, per-action.

**record value** (new!):
One resolved record: the contents of a record option (e.g. `config.wrapper`, `config.profiles.<name>.wrapper`), or a literal of the same shape.

**inline mode** (new!):
The `mkWrapkitBin` input form that passes exactly one record inline (`wrapper = { … }`); the mini-eval merges it by ordinary module priority.

**layered mode** (new!):
The `mkWrapkitBin` input form that passes `wrappers = [ <record value> … ]`; the records are normalized, then applied one definition apiece so the second module application merges them.

**`normalizeWrapper`** (new!):
The step that strips `null` fields (and `unset = false`) from a resolved record so it is safe to apply as a definition.

**mini-eval** (new!):
The small evaluation run by `mkWrapkitBin` through the wrapkit kit, producing the wrapped bin.

**wrapper schema** (new!):
The typed model of the full `makeWrapper` surface (env actions, flags, process control).

**wrapper arguments** (new!):
The `makeWrapper` argument list assembled from the effective env, flags, and process control.

## Naming & IDs

Identifier patterns:
- Constructor/function names use the `mkWrapkit*` prefix: `mkWrapkitBin` (active), `mkWrapkitWrapperOption` (active, public), and `mkWrapkitPkg` (proposed for a later composition constructor).
- The base module file is `wrapkit-base.module.nix`, loaded first into every mini-eval.
- Option paths in the base module: `wrapper.env.<VAR>.<action>`, `wrapper.flags.<action>`, `wrapper.argv0`, `wrapper.chdir`, `wrapper.run`, plus the read-only `output`.
- `<VAR>` is a free-form environment-variable name string; wrapkit assigns no structure to it.
- Result names are owned by the external profile system (`profiles.<name>`); wrapkit does not name results.
- Toolkit and tool-config IDs follow the existing `nix/kits/README.md` conventions and are external to wrapkit.

`wraplib` is the export that holds wrapkit's helper functions: `mkWrapkitBin`, `wrapperType`, `mkWrapkitWrapperOption`.
It is exposed from `nix/kits/wrapkit/default.nix`; no module is exported.

## Interface / How to use

### `mkWrapkitBin`

The primary entry point runs a mini-eval and returns `{ config; drv; }` — the evaluated config and the wrapped bin.
It takes one of two mutually exclusive record inputs — **inline** or **layered**:

```nix
# inline mode — one record, written as definitions
mkWrapkitBin {
  wrappedBin = "foo/tmux";
  wrapper.env.FOO.set = "hello";
}

# layered mode — an ordered list of already-resolved records
mkWrapkitBin {
  wrappedBin = "foo/tmux";
  wrappers = [ config.wrapper config.profiles.<name>.wrapper ];
}
```

```nix
mkWrapkitBin = { wrappedBin, binName ? <derived from wrappedBin>, wrapper ? null, wrappers ? null, specialArgs ? {}, ... }@args:
  let
    records =
      if wrappers != null
      then map normalizeWrapper wrappers
      else lib.optional (wrapper != null) wrapper;
    evaled = wrapkit.eval {
      pkgs = pkgs;
      config = { _module.args = { inherit wrappedBin binName; }; };
      moreModules = map (r: { wrapper = r; }) records;
    };
  in
  { config = evaled; drv = evaled.output; };
```

- `wrappedBin` — the binary to wrap: a path string (`"${somepkg}/bin/foo"`) or a derivation, resolved with `lib.getExe`.
- `binName` — the command name; defaults to the command name of the resolved binary, `baseNameOf (lib.getExe wrappedBin)` (see Output construction & layouts).
  A non-null value selects the `$out/bin/<binName>` layout; `null` selects the single-file `$out` layout.
- `wrapper` (inline mode) — one record written as definitions; the mini-eval merges it by ordinary module priority, and `lib.mkForce` is available.
- `wrappers` (layered mode) — an ordered list of already-resolved record values; each becomes one definition of the base module's `wrapper` option, so the second module application merges them.
- `specialArgs` — extra values threaded into the mini-eval (the kit injects `wrappedBin` and `binName` as module args).

The two record inputs are asserted mutually exclusive.
`normalizeWrapper` runs in layered mode only; inline mode passes the record through untouched, because a record written as definitions may legitimately use `lib.mkForce`.
Neither input is a superset of the other: layered mode is what a host holding resolved `config.*` records can actually produce, whereas inline mode can express priority and clearing — see Environment override model.

A complete, non-toy wiring for tmux.
The host's own record options — named `wrapper` and `profiles.<name>.wrapper` here — hold the shared default and the per-result override; both are resolved values, so the wiring uses layered mode:

```nix
wrapkit = import ./wrapkit; # the `wraplib` export

entrypoint = "/nix/store/…/tmux.conf";

# declared by the host's own modules
wrapper = {
  env = {
    TMUX_CONFIG_ENTRYPOINT.setDefault = entrypoint;
    TERMINFO_DIRS.prepend = [ "${pkgs.tmux.terminfo}/share/terminfo" ];
    TMUX_PLUGIN_RESURRECT_PATH.set = "${resurrect}/share/tmux-plugins/resurrect";
  };
  flags.beforeArgs = [ "-f" entrypoint ];
};

profiles.standalone.wrapper = {
  env.TMUX_CONFIG_ENTRYPOINT.set = "over"; # only `set` wins; the commons' other actions survive
};

tmuxWrapped = wrapkit.mkWrapkitBin {
  wrappedBin = "${pkgs.tmux}/bin/tmux";
  binName = "tmux";
  wrappers = [ config.wrapper config.profiles.standalone.wrapper ];
};
```

`setDefault` in the commons against `set` in the profile is the flagship case: a later layer cannot win a scalar by order, so precedence has to be expressed by the action.

### The `env` part of the record

`wrapper.env` is keyed by environment-variable name; each value is a submodule of actions.
Every action maps to a `makeWrapper` flag (see Wrapper schema for the authoritative mapping).

```nix
wrapper.env.FOO = {
  sep = ":";                             # shared separator for the prepend/append variants; null → the emitter's ":"
  set = "hello";                         # --set FOO hello
  setDefault = "fallback";               # --set-default FOO fallback
  unset = null;                          # true → --unset FOO; null → no flag
  prepend = [ "/a" "/b" ];               # --prefix FOO : /a:/b
  append = [ "/c" ];                     # --suffix FOO : /c
  prependFromFile = [ ./extra-paths ];   # one --prefix-contents FOO : <file contents> per file
  appendFromFile = [ ./more-paths ];     # one --suffix-contents FOO : <file contents> per file
};
```

`prepend`/`append` are lists of strings joined by the VAR's `sep`; the `prependFromFile`/`appendFromFile` variants take file paths and emit one operation per file.

### The `flags` part of the record

`wrapper.flags` models the args passed to the wrapped program itself.

```nix
wrapper.flags.beforeArgs = [ "--config" cfg ];     # one --add-flag per element, quoted
wrapper.flags.afterArgs = [ "-d" ];                # one --append-flag per element, quoted
```

### Process control

Process-control options live at the top level of the record:

```nix
wrapper.argv0 = null;     # null → no flag; "inherit" → --inherit-argv0; "resolve" → --resolve-argv0; <str> → --argv0 <str>
wrapper.chdir = null;     # null → no flag; <str> → --chdir <str>
wrapper.run = null;       # null → no flag; list of commands → --run <cmd> per element
```

### Wiring the external profile system

`profiles.*` is external; wrapkit only supplies the constructor and the option schema.
The host installs a record option at the root (commons) and under each profile (override); the field names are its choice, and both are resolved **record values** by the time it builds:

```nix
# declared by whatever modules the host imports
wrapper.env.FOO.setDefault = "hello";
profiles.standalone.wrapper.env.FOO.set = "over"; # override!

profiles.standalone.pkg = wrapkit.mkWrapkitBin {
  wrappedBin = "${pkgs.tmux}/bin/tmux";
  wrappers = [ config.wrapper config.profiles.standalone.wrapper ];
};
```

That is layered mode: the host holds resolved `config.*` records, which are normalized and then applied in order, so accumulating fields concatenate and a scalar set by two layers is a genuine conflict — see Environment override model.

A host that owns its record inline instead uses inline mode, where `lib.mkForce` states priority and disjoint actions merge on their own:
`mkWrapkitBin { wrappedBin = "…"; wrapper.env.FOO.set = lib.mkForce "over"; }`.

The host owns the record-option declarations — the site and field name are its choice; wrapkit exports the schema so it does not have to re-declare the type — see Environment override model.

## Environment override model

The override system revolves around one reusable **wrapper record**: the typed schema of one wrapper's whole surface — `env`, `flags`, `argv0`, `chdir`, `run` — in `makeWrapper` vocabulary.
The same record schema backs every install site, and the host picks both the site and the field name:

- installed at the root of an evaluation it yields the **commons** — e.g. `config.wrapper`;
- installed at a nested site it yields an **override** scoped to the consumer there — e.g. `config.profiles.foo.wrapper`.

The consumer is a **result** (`profiles.foo.<result-using-us>`): something that builds a wrapped bin and consumes the effective wrapper.
The **effective wrapper** for a result is the commons merged with the result's scoped override.

Merging is **per action**.
An override that sets one action for a VAR (e.g. `wrapper.env.FOO.set`) leaves the commons' other actions for that VAR (e.g. `wrapper.env.FOO.prepend`) inherited.
This is what makes overrides composable rather than wholesale replacements.

The merge happens **inside `mkWrapkitBin`**, across two module applications — see Two module applications, not one.

The mini-eval runs through `kitsys` (`defineEval`), so it gains assertions/warnings and `config.lib.extendWith` (see Design options).

### Two module applications, not one

A host reaches `mkWrapkitBin` from its own evaluation, and that evaluation is itself a module system.
So two module applications are at play:

1. the **host** application resolves every install site on its own: the root record option (e.g. `config.wrapper`) merges the host's commons definitions, while a nested one (e.g. `config.profiles.foo.wrapper`) merges whatever another module set for that profile.
   Each comes out as a concrete record value.
2. the **mini-eval** inside `mkWrapkitBin` applies those records to the base module, which is where the commons and the override actually meet.

The module system merges *definitions* and offers no way to read an option's definitions back out, so a resolved record is all the host can hand over.
`mkWrapkitBin` therefore accepts one of two mutually exclusive inputs:

- **inline mode** — one `wrapper = { … }` record written as definitions.
  It enters the mini-eval untouched, so merging is ordinary module priority and `lib.mkForce` is available.
- **layered mode** — `wrappers = [ <record value> … ]`, an ordered list of resolved records.
  Each is passed through `normalizeWrapper` and applied as one definition of the base module's `wrapper` option, so the second module application does the merging.

#### Why a resolved record must be normalized

A resolved record has every field present, unset ones as `null`, and carries no priority information.
Applied raw, it defines every field at normal priority and therefore conflicts with every field the other layer touches — including fields the author never set.
`normalizeWrapper` strips those `null` fields (and `unset = false`) in layered mode only, which removes exactly that second class of collision.
What it cannot remove is a genuine disagreement: two records setting the same scalar.

#### Merge rules

- **Accumulating fields concatenate** across records, in layer order: `wrapper.env.<VAR>.prepend` / `append` / `prependFromFile` / `appendFromFile`, `wrapper.flags.beforeArgs` / `afterArgs`, and `wrapper.run`.
- **Every other field is a scalar**, and two records setting the same scalar is a genuine conflict the eval rejects.
  Layer order decides the order of accumulated lists only.
- **Precedence is expressed by the action, not by layer order**: the commons sets `setDefault`, the profile sets `set`, and the emitter resolves `set` above `setDefault`.
  A same-field clash across layers is an authoring error, not something the merge silently settles.
- A VAR whose fields are all `null` after normalisation drops out, so the emitter's defaults apply.

#### The schema has no defaults

Defaults were removed from the schema, because with module priority a default *is* a definition: a `sep` defaulting to `":"` would collide with a `sep` another layer sets.
`sep`, `unset`, and every list now default to `null`.
The effective defaults (`":"`, `false`, `[]`) are applied by the **emitter** at assembly time, so "absent" simply means "use the default here".
This is also what keeps `normalizeWrapper` a plain strip-`null`.

#### What neither mode supports

- passing an already-resolved record as the inline `wrapper` (a `config.*` value smuggled into inline mode).
  Resolution materializes a value for every field, so each field arrives with two equal-priority definitions: `nullOr str` errors with `defined both null and not null`, `str`/`bool` error with conflicting definition values, and `listOf` concatenates.
  Blanket priority does not rescue it either — `lib.mkForce`-ing the whole record discards commons-only fields and `lib.mkDefault`-ing it discards the override.
  The failure is loud but cryptic, and it cannot be detected reliably, so it has to be documented rather than guarded.
- clearing or replacing across the two module applications.
  A record is a value, and values carry no priority markers, so a later record cannot clear or outrank an earlier one; its list entries simply append.
  Only `unset = true` can neutralise a VAR, and only when no other record sets the same VAR.
- element-wise subtraction from an inherited list, in either mode.

#### Clearing within one module application

Clearing works where definitions meet, i.e. inside the host's own `wrapper.*` definitions, via `lib.mkForce`:
`wrapper.env.FOO.set = lib.mkForce null`, `wrapper.env.FOO.prepend = lib.mkForce []`, `wrapper.env.FOO.unset = lib.mkForce true`.

Those markers do not survive resolution, which is why layered mode cannot express the same thing.
A replacement story for layered mode is deferred.

Verified in a plain mini-eval (`findings/spikes/env-merge.nix` in Related artifacts), with the commons setting a `prepend` for one VAR and a later definition differing:

| later definition, same VAR | outcome |
|---|---|
| nothing | the commons value survives |
| `set` a value where the commons left `set` at `null` | eval error — `defined both null and not null` |
| `prepend` another list | `prepend` concatenates; nothing was replaced |
| `set = lib.mkForce null` | the scalar is cleared |
| `prepend = lib.mkForce []` | the list is cleared |
| `unset = lib.mkForce true` | the VAR is neutralised |

`profiles.*` is not defined by wrapkit.
The profile system is a separate, future concept that wrapkit plugs into via the `mkWrapkitBin` constructor, as sketched in Interface / How to use.

`mkWrapkitWrapperOption` is a public export, exposed through `wraplib`, so an external profile system installs its record options from the same schema.
The commons lives at the evaluation root (`wrapper.*`); a `wrapkit` namespace was considered and set aside to keep the user-facing path short.
The kit is one evaluation; `mkWrapkitBin` runs it per bin with `wrappedBin` and `binName` as module args — see Placement / Scope.

## Wrapper schema

The wrapper schema is the typed model of the full `makeWrapper` surface, so every wrapper argument a toolkit hand-emits today becomes expressible data.
Mapping to `makeWrapper` flags (source: `pkgs/build-support/setup-hooks/make-wrapper.sh`):

Environment variables, keyed by `VAR` under `env`:
- `sep` (`nullOr str`, default `null`) — the shared separator reused by every prepend/append variant for this VAR; not itself a flag. `null` means the emitter applies `":"`.
- `set` (`nullOr str`, default `null`) → `--set VAR VAL`.
- `setDefault` (`nullOr str`, default `null`) → `--set-default VAR VAL`.
- `unset` (`nullOr bool`, default `null`) → `--unset VAR`. `null` means no flag; the emitter treats `unset = false` as a no-op.
- `prepend` / `append` (`nullOr (listOf str)`, default `null`) → one `--prefix` / `--suffix VAR <sep> VAL`, with the list joined by `sep`.
- `prependFromFile` / `appendFromFile` (`nullOr (listOf path)`, default `null`) → one `--prefix-contents` / `--suffix-contents VAR <sep> FILE` per file.

Flags for the wrapped invocation, under `flags`:
- `beforeArgs` / `afterArgs` (`nullOr (listOf str)`, default `null`) → one `--add-flag` / `--append-flag` per element, each `@Q`-quoted by the assembler.

Process control, top-level:
- `argv0` (`null | "inherit" | "resolve" | str`, default `null`) → no flag / `--inherit-argv0` / `--resolve-argv0` / `--argv0 NAME`.
- `chdir` (`nullOr str`, default `null`) → `--chdir DIR`.
- `run` (`nullOr (listOf str)`, default `null`) → `--run COMMAND` per element.

Schema notes:
- The schema has no defaults: every field defaults to `null`, `sep` and `unset` and every list included.
  Under module priority a default *is* a definition, so a non-null default would collide with a layered record rather than yield to it.
  The effective defaults (`":"`, `false`, `[]`) are applied by the emitter at assembly time.
- A per-VAR `sep` avoids repeating the separator across the prepend/append variants.
  It is validated as a non-empty single character: it expands through the shell's `IFS`, so anything else would not split as a literal string.
- `prepend` / `append` join their list into one de-duplicated value; the `prependFromFile` / `appendFromFile` variants emit one `--prefix-contents` / `--suffix-contents` operation per file, whose VAL is the file's contents.
- The per-action model is what lets an override set `wrapper.env.FOO.set` while inheriting a commons `wrapper.env.FOO.prepend`.

### makeWrapper semantics the assembler must respect

`makeWrapper` emits **shell lines in argument order**, so a later line for the same variable overrides an earlier one.
The flags are therefore ordered operations, not declarative settings, and the assembler has to emit them in the right sequence.

- **Emit the scalar family before the prefix/suffix family** for the same VAR.
  `--prefix` writes the variable, so a `--set` emitted afterwards wipes it.
  Within the scalar family, order `setDefault`, then `set`, then `unset`, so `unset` has the last word.
- **Last scalar write wins**: `--set` after `--unset` wins, `--unset` after `--set` wins, and a second `--set` keeps the later value.
  `--set-default` only assigns when the variable is unset at that point.
- **Join, do not repeat.** Several `--prefix` calls for one VAR land in *reverse* call order, while the order within a single call is preserved.
  Joining the schema's list with `sep` into one `--prefix VAR SEP <joined>` call is what makes the resulting order predictable.
- **De-dup moves to front for `--prefix`** rather than skipping: each component removes the first existing instance of itself and re-prepends, so a value the variable already held moves forward.
  `--suffix` leaves a component that is already present untouched.
- **Avoid `--prefix-each` / `--suffix-each`** for the ordinary list case: they reverse the relative order, and their values argument is a single whitespace-split string (`--prefix-each VAR SEP "/a /b"`), which fails when it is not quoted.
  The `-contents` variants follow the same whitespace-split, reversed pattern.
- **`sep` expands through the shell's `IFS`**, so an empty or multi-character `sep` does not behave as a literal string split.
- **Arg flags**: the assembler uses the singular `--add-flag` / `--append-flag`, one call per element, so each element is `@Q`-quoted on its own. The plural `--add-flags` / `--append-flags` passes one verbatim string the shell interprets, and is avoided.
- **`argv0`** maps to `-a NAME`, `--inherit-argv0` to `-a "$0"`, and `--resolve-argv0` is a no-op for shell wrappers; when two of them are given the last one wins.
- The final line is `exec <argv0args> "ORIGINAL" <flagsBefore> "$@" <flagsAfter>`, and `wrapProgramShell` renames the wrapped target to `.<basename>-wrapped`.

Source: `pkgs/build-support/setup-hooks/make-wrapper.sh` in nixpkgs.
Reproducible evidence: `findings/spikes/makewrapper-flags.nix` in Related artifacts.

## Output construction & layouts

`output` is a read-only package option built from the effective wrapper record.
The base module assembles the **wrapper arguments** (one `makeWrapper` argument list) from that record, then builds the wrapped bin.
Because the schema has no defaults, the assembler applies the effective defaults while assembling: a `null` `wrapper.env.<VAR>.sep` means `":"`, a `null` `unset` means no flag, and a `null` list contributes nothing.
The builder never uses `replaceBinsInPkg`/`copyFromPkg`, because it generates a single binary rather than copying a package.

The layout is selected by `binName`.

bin-dir layout (default) — `$out/bin/<binName>`:

```nix
output = runCommandLocal binName { nativeBuildInputs = [ makeWrapper ]; } ''
  mkdir -p $out/bin
  makeWrapper ${wrappedBin} $out/bin/${binName} ${lib.escapeShellArgs wrapperArgs}
'';
```

single-file layout — `$out` is the executable file, opted into with `binName = null`:

```nix
output = runCommandLocal "${wrappedBinName}-wrapped-bin" { nativeBuildInputs = [ makeWrapper ]; } ''
  makeWrapper ${wrappedBin} $out ${lib.escapeShellArgs wrapperArgs}
'';
```

Layout tradeoff:
- bin-dir keeps `binName` effective as the command name, composes into `PATH` environments (e.g. `home.packages` / `buildEnv`), and resolves via `lib.getExe`.
- single-file is minimal (one file), but the executable's on-disk name is the hash-prefixed derivation name and it lives outside any `bin/`, so it cannot be added to `PATH` and `lib.getExe` does not resolve it.

The default `binName` is the *command name* of the resolved binary — `baseNameOf (lib.getExe wrappedBin)` when `wrappedBin` is a derivation, and `baseNameOf` of the path string otherwise.
It is deliberately not `lib.getName`/`pname`: those differ for neovim (`neovim` vs the command `nvim`), and the command name is what a wrapper must preserve.
`tmux`, `zsh`, and `git` agree either way; neovim is the case that decides the rule.

`lib.getExe` needs `meta.mainProgram`.
When it is absent, wrapkit requires an explicit `binName` rather than falling back.
A fallback would silently derive the wrong name: `pkgs.binutils` resolves to `binutils-wrapper`, so the derived `binName` would be `binutils-wrapper`.
Multi-binary packages without `meta.mainProgram` are therefore the failure mode, and the fix is an explicit `binName`.

The path-string shape is unaffected: `baseNameOf` on a literal `"${pkg}/bin/foo"` always yields `foo`.
A path string that does not end in a program name (a directory, or a trailing slash) makes the derived name meaningless; that is a caller error, not something to paper over.

## Placement / Scope

wrapkit-system is delivered as both a **kit** and a set of **embeddable helpers**.
The kit half makes it usable standalone and composable with the repo's other kits (`lib.extendWith` support).
The helpers supply the `wrapper` record type and its option constructor (`mkWrapkitWrapperOption`), which a host installs at chosen sites; the base module stays internal to `mkWrapkitBin`.

Where things may be defined:
- the **commons** at the root of a host evaluation, wherever the host installed the record option (e.g. `config.wrapper.*`);
- an **override** at a nested site, again wherever the host installed it (e.g. `config.profiles.<name>.wrapper.*`);
- the **wrapper records** inside the `mkWrapkitBin` call — one inline `wrapper` record, or an ordered `wrappers` list of resolved record values.

What wrapkit does and does not own:
- wrapkit **does** own the `wrapper` record type, the base module, the wrapper-argument assembly, and the `mkWrapkitBin` constructor.
- wrapkit **does not** define `profiles.*`; the profile system is external.
- wrapkit's target is a **single bin**; package/multi-bin composition (bins plus config dirs) is outside it, and is left to a later `mkWrapkitPkg` constructor rather than to each toolkit.

The kit is one evaluation; each `mkWrapkitBin` call runs it with `wrappedBin` and `binName` supplied as module args.
The mini-evals share the kit's base module and the wrapper schema rather than defining their own eval.

## Env override as a merge primitive (env default as module definition)

The familiar feature — "install an env default at a root and let a consumer override it" — maps onto the Nix module primitive rather than onto a bespoke merge mechanism.

Within one module application — the host's, or the mini-eval's — the mapping is onto the Nix module primitive:

- "the commons" ↔ a record-option definition at the evaluation root.
- "an override scoped to a consumer" ↔ a record-option definition at that consumer's site (a nested attr-path, e.g. `profiles.foo`).
- "an override wins within one application" ↔ module priority: the later definition carries `lib.mkForce` for the actions it must win. Module order alone does not establish precedence for scalars.
- "an override touches one action but not the rest" ↔ two modules defining different sub-options of the same VAR; the module merge keeps both.

Because the whole override story is just module definitions at different sites, the same `wrapper` record type serves both halves with no special object for "an override".

Across the two module applications a record is a *value*, so no priority marker survives: precedence is not expressed by layer order but by the action the record sets.

- "the commons" ↔ the first element of `wrappers`.
- "an override scoped to a consumer" ↔ a later element.
- "an override wins across applications" ↔ the override sets a *stronger action* for the same field — `wrapper.env.FOO.setDefault` in the commons, `wrapper.env.FOO.set` in the profile; the emitter resolves `set` above `setDefault`.
- "an override touches one action but not the rest" ↔ the same per-VAR action union; accumulating fields (`prepend`/`append`/`run`/`flags.*Args`) concatenate in layer order.
- two records setting the same scalar is not an override but a conflict the eval rejects.

Both paths produce the same effective wrapper for inputs that agree, so the choice is about what the caller can express, not about semantics.

The record option comes from one constructor, used like any other option definition — it picks neither the site nor the name:

```nix
# at the root, field `wrapper` → config.wrapper
{ options.wrapper = wrapkit.mkWrapkitWrapperOption { }; }

# under a profile, field `wrapper` → config.profiles.foo.wrapper
{ options.profiles.foo.wrapper = wrapkit.mkWrapkitWrapperOption { }; }

# the same constructor under a differently named field → config.profiles.foo.cfg
{ options.profiles.foo.cfg = wrapkit.mkWrapkitWrapperOption { }; }
```

Where the option is declared is ordinary host code, so the commons and a per-site override are the same kind of value from the same source.

`mkWrapkitWrapperOption` ships as a public export through the `wraplib` export, so a host installs the option from the same source — see Environment override model.

## Design options

Localized alternatives within the chosen direction.

**Output layout** — bin-dir (default) vs single-file.
Decision criteria: use bin-dir whenever the bin must compose into `PATH`, `buildEnv`, `home.packages`, or resolve via `lib.getExe`; use single-file only when a single self-contained executable file is wanted and PATH composition is irrelevant.

**Env schema shape** — per-VAR action submodule (active) vs ordered action list (deferred).
Decision criteria: use the per-VAR submodule when typed, per-action override merging matters (the composability goal); use an ordered list when explicit operation ordering is required and wholesale replacement is acceptable.
The per-VAR form loses strict ordering of operations within one VAR; the ordered form loses the typed per-action merge.

**Mini-eval substrate** — `kitsys` (`defineEval`, active) vs plain `lib.evalModules`.
Decision criteria: the mini-eval runs through `kitsys` so it gains assertions/warnings and `config.lib.extendWith`; plain `lib.evalModules` would keep it dependency-free but cannot offer `lib.extendWith`, which needs `_kitState.currentEval` — only `defineEval` initialises it.

## Alternatives & Tradeoffs

Whole-direction alternatives considered during discovery.

**Model A — record option constructor.**

```nix
mkWrapkitWrapperOption = { }: lib.mkOption { type = wrapperType; default = {}; };
# usage: { options.mywrapper = mkWrapkitWrapperOption { }; }
```

- Advantages: minimal; the override is implicit in where the option is declared; no results registry.
- Costs: the host still calls the wrapped-drv generator itself; the record-install and drv-generation halves stay separate.

**Model B — global results tree.**

```nix
wrapkit.wrapper = { /* commons wrapperType */ };
wrapkit.results.<name> = { wrapper = { /* override */ }; package = pkgs.tmux; bin = "tmux"; };
wrapkit.results.<name>.out; # the wrapped drv
```

- Advantages: results are first-class, keyed by name; one tree to inspect.
- Costs: a results registry and naming scheme wrapkit does not otherwise need; couples the generator to the tree.

**Model C — type + normalizer only.**

```nix
normalizeWrapper = record: /* the record with every null field dropped */;
```

- Advantages: most explicit; no magic; nothing auto-installed.
- Costs: every host repeats the install boilerplate; no shared constructor for the drv.

**Model D — `mkWrapkitBin` over a small internal module system (active).**

```nix
mkWrapkitBin : { wrappedBin, binName ? <derived>, wrapper ? null, wrappers ? null } -> { config; drv; };
```

- Advantages: one constructor does both halves; the merge is ordinary module merge; the host stays free to keep `profiles.*` external.
- Costs: a mini-eval per bin; two record inputs to document (an inline `wrapper` record, or an ordered `wrappers` list of resolved records); a resolved record smuggled into the inline `wrapper` fails with a cryptic module-system error (see Environment override model / Two module applications, not one).

**Decision criteria**: choose Model D when a single constructor and module-priority composability are wanted and a mini-eval per bin is acceptable; Model A when record install and drv generation should be kept apart; Model B when the host needs a named results registry; Model C when minimal machinery and full host control win over reuse.

Models A/B/C were deferred in favor of D, not rejected outright.

## Related artifacts

- `nix/SPEC-READY-wrapkit-system/EXPLO-*.md` — the exploration docs (`BRIEF`, `env-override-model`, `wrapped-drv-generator`, `wrapper-schema`, `packaging-composition`, `kit-half`) that feed this spec, including the full discussion log.
- `nix/SPEC-READY-wrapkit-system/findings/spikes/*.nix` — the M1 probe scripts (`env-merge`, `makewrapper-flags`, `binname-derivation`) behind the merge, flag-semantics, and `binName` conclusions recorded in this spec.
- `nix/mypkglib.nix` — the current shared wrapped-pkg builder (`replaceBinsInPkg`); wrapkit replaces it for the single-bin case.
- `nix/kits/toolkit-modules/{tmuxkit,zshkit,nvimkit}-base.toolkit-module.nix` — the current per-toolkit wrapper blocks whose drift this spec unifies.
- `pkgs/build-support/setup-hooks/make-wrapper.sh` in nixpkgs — the primitives the wrapper schema models.
- `nix/kit-system/default.nix` — `newKit`, `defineEval`, `lib.extendWith`; the kit substrate the mini-eval runs on.
- `nix/SPEC-DRAFT-hm-toolconfigs-integration-CRAZY!/SPEC.md` — sibling draft proposing per-home output recomputation via `lib.extendWith`; informs the result/outputs API.
- `nix/DESIGN_config_system.md` — the Kit/Module/Preset/Profile/Config vocabulary wrapkit's "kit + embeddable helpers" nature fits into.
