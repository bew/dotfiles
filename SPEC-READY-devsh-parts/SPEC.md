# [READY] devsh-parts Nix-native dev shell library

## Introduction

Developer shells are the part of a project's tooling that everyone enters but nobody wants to
configure twice.
In this repo the shell is declared with `numtide/devshell`, by calling its Nix interface
(`mkShell`) directly from `flake.nix` — no `devshell.toml` is involved.
The friction is documentation, not format: devshell documents its TOML configuration and its keys,
while the Nix-level interface — what `mkShell` takes, how a configuration becomes a shell, what
the returned derivation carries — is left to the source code.
In practice every change to the shell begins by reading `modules/devshell.nix` to rediscover the
interface.

Two known answers exist and neither fits.
`devenv` gives the ergonomics, with services, processes, and language presets attached — a large
surface to adopt for a shell that needs tools and a few variables.
`devshell` keeps the surface small but documents the path this repo does not take, so its Nix
interface has to be inferred from the implementation.
What is missing is a description language that is Nix all the way down, small enough to read in one
sitting, and documented at the surface people actually use.

`devsh-parts` is that library, published as a flake input so a shell description can be shared
beyond the project that wrote it.
A shell is a Nix module: a list of packages, an attribute set of environment variables, and two
lists of shell hooks.
The module system supplies the composition — `imports` for sharing a base shell, ordinary option
merging for combining partial descriptions — so nothing bespoke is invented for merging.
The result is a derivation that behaves like the shells people already know: entered by
`nix develop`, by `nix-shell`, by direnv on `cd`, or run directly to execute one command in the
declared environment.

The use-cases it must serve:

- a project shell carrying its build tools and environment variables, with no ceremony beyond one
  module file;
- a base shell defined once and imported by several projects, each adding its own packages and
  variables without copying the base;
- automation that runs a project command in exactly the environment a developer would get, without
  duplicating `PATH` and variable setup in a CI script;
- direnv users who want the shell applied on entering a directory, and who must not be surprised by
  what runs at that moment.

Inspirations, and what each contributes:

- `numtide/devshell` — the artifact model: a `buildEnv` holding the packages plus an entrypoint and
  an env script, the entrypoint flag vocabulary (`--pure`, `--prj-root`), and the direnv-aware
  handling of the project root.
- `devenv` — a feasibility reference for "a shell described declaratively", rejected as a scope
  reference.
- `flake-parts` and `drv-parts` — the composition stance behind the name: parts combined by the
  module system rather than by a bespoke merge.
- `nix/SPEC-DRAFT-wrapkit-system` — the per-variable environment action vocabulary (`set`,
  `set-default`, `unset`, `prefix`, `suffix`), reduced here to the actions a shell actually needs.
- nixpkgs' module system — the evaluator, the option types, and the error messages.

## Interface / How to use

A consumer adds the library as a flake input and calls `mkShell` once per shell.

```nix
# flake.nix — consumer
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    devsh-parts.url = "github:bew/devsh-parts";
  };

  outputs = { self, nixpkgs, devsh-parts, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = devsh-parts.lib.mkShell {
        inherit pkgs;
        modules = [ ./devsh.nix ];
      };
    };
}
```

`mkShell` takes exactly two arguments and returns the shell derivation.
`pkgs` is the package set that builds the shell — the consumer's, not the library's.
`modules` is an ordinary Nix module list, so `imports` works as it does everywhere else.

The shell itself is one module file:

```nix
# devsh.nix
{ pkgs, ... }:
{
  name = "myproject";

  packages = [
    pkgs.just
    pkgs.jq
    pkgs.ripgrep
  ];

  env.MY_VAR = "value";                    # shorthand for env.MY_VAR.set
  env.PATH.prefix = [ ./bin ];
  env.LEGACY_VAR.unset = true;

  hooks.enter = [ ''echo "tools ready"' ];
  hooks.interactive = [ ''export PS1="devsh> "'' ];
}
```

A base shell is shared by importing it, which is the only composition mechanism:

```nix
# shells/base.nix — shared by several projects
{ pkgs, ... }:
{
  packages = [ pkgs.git ];
  env.EDITOR = "nvim";
}

# devsh.nix — project shell on top of the base
{
  imports = [ ./shells/base.nix ];
  packages = [ pkgs.python3 ];
  env.PROJECT_ROOT_HINT = ".";
}
```

Merging follows the module system: `packages` and the hook lists concatenate in `imports` order,
while `env.<VAR>` actions merge per action, so a project can add a `prefix` while inheriting the
base's `set`.

The option surface:

| option | type | default | meaning |
| --- | --- | --- | --- |
| `name` | `str` | `"devsh"` | names the shell, its store path, and its bin |
| `projectRoot` | `nullOr path` | `null` | the project root; required as soon as any path value appears in `env` |
| `rootMarker` | `str` | `".git"` | filename the runtime walk looks for when resolving `PRJ_ROOT` |
| `packages` | `listOf package` | `[ ]` | packages placed in the shell's `buildEnv` |
| `env` | `attrsOf submodule`, scalars coerced to `{ set = …; }` | `{ }` | environment variables and their actions |
| `hooks.enter` | `listOf str` | `[ ]` | shell code run whenever the environment is applied |
| `hooks.interactive` | `listOf str` | `[ ]` | shell code run only in interactive shells |
| `bashPackage` | `package` | `pkgs.bashInteractive` | the bash the entrypoint runs, and whose `bin` goes first on `PATH` |

`name` defaults to `"devsh"`, matching devshell's constant default: the value feeds the store path
name, the entrypoint symlink, and the prompt, and a constant keeps evaluation pure where deriving it
from the consumer's directory would not.
Two shells from different projects both providing `devsh` therefore collide on `PATH`, and prompts
are indistinguishable across projects, which is why every example here sets the option.
The example is the idiom the option exists for, not an optional flourish.

The returned derivation behaves as three things.
It is a `devShell` for `nix develop`, an environment for direnv's `use flake`, and a command runner
through `$out/bin/<name>`:

```sh
nix develop                       # interactive shell, environment applied
nix develop .#ci -- cargo test    # run one command inside the environment
myproject --help                  # same, through the entrypoint on PATH
myproject --pure -- cargo test    # run with an empty environment
```

The entrypoint accepts the flags devshell established:

| flag | effect |
| --- | --- |
| `-h`, `--help` | print usage and exit |
| `--pure` | re-exec under `env -i`, keeping `HOME` and `PRJ_ROOT` |
| `--prj-root <path>` | set `PRJ_ROOT` explicitly instead of resolving it |
| `--` | end flag parsing; the rest is the command |

`--env-bin` from devshell is deliberately absent: it existed to put the command scripts on `PATH`,
and v1 generates no command scripts.

With no command and no flag, the entrypoint starts an interactive `bash` with the environment
applied.
When sourced rather than executed, it applies the environment to the current shell and returns.

## Environment model

`env` is keyed by variable name, and each value is a small submodule of actions rather than a bare
scalar.
A scalar is still what most variables need, so any scalar is coerced into a single `set` action:

```nix
env.MY_VAR = "value";          # env.MY_VAR.set = "value";
```

"Scalar" means anything that converts to a string: a string, a path, a derivation, an integer, or a
float.
Every value is converted with `toString`, so `env.PYTHON = pkgs.python3;` yields the interpreter's
store path, and the conversion happens at evaluation time, in Nix, not in the generated shell.
Paths are the one exception: a path under `projectRoot` is emitted relative to it instead, which
Path values below describes.
The same conversion applies inside the actions: `set`, `set-default`, and every element of `prefix`
and `suffix` accept a scalar.

Each variable accepts these actions:

| action | type | default | effect |
| --- | --- | --- | --- |
| `set` | scalar, `null` allowed | `null` | assign the variable |
| `set-default` | scalar, `null` allowed | `null` | assign it only when currently unset or empty |
| `unset` | `bool` | `false` | remove it from the environment |
| `prefix` | `listOf scalar` | `[ ]` | put the values before the current one |
| `suffix` | `listOf scalar` | `[ ]` | put the values after the current one |
| `sep` | `str` | `":"` | separator used when joining values and the existing one |
| `allowEval` | `bool` | `false` | treat the action values as shell code instead of literals |

The actions exist so that a project can add to a variable without restating it, which is the case
that makes `PATH` usable and every other variable merely convenient.
`set-default` covers the opposite case: a fallback the user may override from their own
environment.

Emission follows a fixed order per variable — `unset`, `set-default`, `set`, `prefix`, `suffix` —
so that an action sequence reads the same way it executes:

```sh
# env.LEGACY_VAR.unset = true;
unset LEGACY_VAR

# env.EDITOR.set-default = "vi";
[[ -n "${EDITOR:-}" ]] || export EDITOR='vi'

# env.MY_VAR = "value";
export MY_VAR='value'

# env.PATH.prefix = [ "/a" "/b" ];
export PATH='/a:/b'"${PATH:+:$PATH}"

# env.PATH.suffix = [ "/c" ];
export PATH="${PATH:+$PATH:}"'/c'
```

`set-default` expands the variable being assigned only to test whether it has a value, so the
default itself still arrives as a quoted literal.

Values are literal strings, already converted at evaluation time, and every one of them is emitted
single-quoted.
A value containing a single quote is escaped the usual shell way (`'\''`), so no value can escape
its quoting.
Nothing inside a value expands: `env.LITERAL = "$HOME/bin";` exports the characters `$HOME/bin`,
not the user's home directory, and a value containing `$(…)` is never executed.
The `PRJ_ROOT` reference that path values render against is the only thing that expands, and the
description author never writes it.

`allowEval` is the opt-in escape from that rule, and it is one flag per variable rather than a
modifier per action:
when it is set, the values of `set`, `set-default`, `prefix`, and `suffix` are shell code instead of
literals, while `unset` is unaffected because it is a boolean.
An eval'd value is emitted double-quoted, so expansions, parameter defaults, and command
substitution run when the environment is applied, while word splitting does not:

```sh
# env.GIT_SHA = { allowEval = true; set = "$(git rev-parse --short HEAD)"; };
export GIT_SHA="$(git rev-parse --short HEAD)"

# env.NPM_PREFIX = { allowEval = true; set-default = "$HOME/.npm-global"; };
[[ -n "${NPM_PREFIX:-}" ]] || export NPM_PREFIX="$HOME/.npm-global"

# env.PATH = { allowEval = true; prefix = [ "$(npm bin)" ]; };
export PATH="$(npm bin)${PATH:+:$PATH}"
```

The default stays literal, so a description that does not ask for `allowEval` keeps the guarantee above:
nothing in its values expands, and nothing in them executes.

Two costs come with the flag, both of them the author's to manage.
An expansion that produces the variable's separator becomes several entries at once, since the
joined result is split by the shell's own reading of `PATH`-style variables, not by the library.
An expansion that produces a double quote breaks the quoting of the generated line, which is
visible immediately as a shell syntax error rather than silently.
Eval'd values are also exempt from path relativization, because a path value is only relativized
when it arrives as a Nix path rather than as shell code.

`set` combined with `prefix` is therefore meaningful (assign, then prepend), while `unset` combined
with `set` is redundant — the same as `set` alone — and is documented rather than rejected.

Merging is the module system's: two modules contributing `prefix` entries concatenate in `imports`
order, so a base shell's entries come first and outrank the project's for `PATH`-style variables.
Two modules contributing `set` for the same variable is a conflict, reported as one, and resolved
deliberately with `mkForce` rather than by a precedence rule invented here.

The prefix and suffix lists are joined with the variable's `sep`, and joined to the existing value
with the same separator.
The empty case is guarded (`${PATH:+:$PATH}`) so a variable that was unset does not acquire a
leading or trailing separator.

### Path values

A path value is treated differently from every other scalar, because `toString` is the wrong answer
for a path inside the project: it bakes an absolute location into the derivation, so the shell's
store path changes with the checkout and the shell points at files that edits no longer reach.

`projectRoot` is the classifier. When it is set, any path value that lies under it is emitted
relative to `PRJ_ROOT` instead of being converted to an absolute path:

```nix
{
  projectRoot = ./.;

  env.DATA_ROOT = ./data;            # export DATA_ROOT="${PRJ_ROOT}"'/data'
  env.PATH.prefix = [ ./bin ];       # export PATH="${PRJ_ROOT}"'/bin'"${PATH:+:$PATH}"
  env.WORKSPACE = ./.;               # export WORKSPACE="${PRJ_ROOT}"
  env.CACHE_DIR = "${./cache}";      # export CACHE_DIR="/nix/store/…-cache"
  env.RUSTC = pkgs.rustc;            # store path, untouched
}
```

The rules, in order:

- A string is never relativized. Interpolating a path into a string (`"${./cache}"`) is therefore
  the explicit way to ask for a store copy, since that is what interpolation of a path does.
- A path under `projectRoot` is relativized. The root itself becomes a bare `$PRJ_ROOT`, with no
  trailing separator.
- A path outside `projectRoot` is converted with `toString`, which covers store paths and paths from
  other flakes.
- A path value with no `projectRoot` set is an evaluation error naming the option and the value,
  raised only when such a value exists — a shell without path values needs no `projectRoot`.

`prefix` and `suffix` go through the same conversion, since project directories on `PATH` are the
main reason the feature exists.

Relativizing makes the shell's store path independent of where the checkout lives, which is the
intended gain and also the reason the resulting value is meaningful only inside the shell: outside
it, `$PRJ_ROOT` is unset.

### Open Questions

1. `prefix` does not de-duplicate against the existing value. Re-entry is handled by stripping on
   the shell side (see Shell artifact), which covers `PATH` and similar path lists but not a
   variable that merely accumulates strings.
   Non-blocking. De-duplication by default would surprise more than it helps; the question is
   whether the artifact's stripping is enough to leave it out.

## Shell artifact

`mkShell` returns one derivation. This section says what it holds, and what entering it does.

"Applying the environment" always means sourcing `env.bash` into the current shell.
The same file serves `nix develop`, direnv, and the entrypoint, which is what keeps the three entry
paths from drifting apart.

### What the derivation contains

- A `buildEnv` of `packages`, which is the derivation's `$out`.
- `env.bash`, generated from the evaluated description.
- `entrypoint`, generated the same way.
- `$out/bin/<name>`, a symlink to `entrypoint`, so the shell is also runnable as an ordinary
  executable.
- `passthru.config`, the evaluated option tree, and `passthru.entrypoint`, its path.

Both scripts have the artifact's own store path substituted into them at build time, so nothing is
exported merely so the files can find each other.

`pkgs.mkShell` is deliberately unused. It would put stdenv's whole build environment into the
shell and produce something that is only a development shell; the `buildEnv` plus `env.bash` shape
produces one artifact that can be entered or executed, which is what makes direnv, `nix develop`,
and a direct run share a single implementation.

### Entering the shell

Every entry path runs the same file, and `env.bash` does this work in this order:

1. Clear build-time noise: the stdenv and `nix-shell` variables (`NIX_BUILD_TOP`, `NIX_BUILD_CORES`,
   `stdenv`, `system`, `builder`, `out`, and the temp-directory set) are unset, so the shell is not
   a half-initialized build environment.
2. Resolve `PRJ_ROOT`, unless the caller already set it.
3. Export `PRJ_ROOT`.
4. Strip the artifact's own directories from `PATH`, then prepend `$out/bin` and the `bashPackage`
   bin directory.
5. Emit the `env` actions in the fixed order of the environment model.
6. Run `hooks.enter` entries in order.
7. Run `hooks.interactive` entries in order, under an interactive-shell guard.

Sourcing the file from a real shell and letting `nix develop` or direnv apply it therefore differ
only in which of steps 6 and 7 run, and in whether a prompt follows.

### Resolving `PRJ_ROOT`

Three cases, in order:

- A value already present wins without inspection. This is how `entrypoint --prj-root <path>` takes
  effect, and it also lets a caller pin the root from outside.
- Otherwise the shell walks up from `$PWD` looking for `rootMarker`, and the first ancestor that
  contains it becomes the root.
- Otherwise the root is `$PWD`.

The walk is what makes entering from a subdirectory behave, and it applies under `nix develop` too.
That is a deliberate difference from devshell, whose `--prj-root` handling sits in the entrypoint
binary and is therefore unreachable through `nix develop`, which sources the profile hook instead of
running the entrypoint.

Falling back to `$PWD` keeps the shell usable outside any project. It is only consequential for a
description that relativized path values, since those render as `$PRJ_ROOT/<rel>` and would then
point at the wrong tree.

### Re-entry

`env.bash` is written to be safe to apply repeatedly, because direnv re-applies it on every load and
on every reload after a change.

`PATH` is stripped before being prepended, so the two artifact directories do not accumulate.
`hooks.enter` and `hooks.interactive` run on every application, so hook entries must be idempotent
and quiet: a hook that appends to a variable or prints a banner will do so again on the next `cd`,
and under direnv the output appears then rather than at shell start.

### Under direnv

direnv evaluates the environment `nix print-dev-env` prints, and that output ends by evaluating the
shell hook, which is what sources `env.bash`.

Four consequences follow, and all are accepted rather than worked around:

- Application happens in a non-interactive bash, so the interactive hooks are skipped and nothing
  may assume a terminal.
- Application happens on `cd` and on reload, not once per session, hence the idempotence
  requirement above.
- Only the environment diff survives direnv's subprocess, so a hook entry can export variables but
  cannot usefully define shell functions or aliases.
- No `profile.d` sourcing is performed. Sourcing it would have delivered exported variables but
  silently dropped the shell functions packages ship there, which makes behaviour depend on entry
  mode; a description that needs it can source the files from `hooks.enter` and accept that
  asymmetry explicitly.

### The entrypoint executable

Running `$out/bin/<name>` applies the environment and then runs what it was given.

| invocation | effect |
| --- | --- |
| `-h`, `--help` | print usage |
| no arguments | start an interactive bash with the environment applied |
| `--pure` | re-exec under a cleared environment, keeping `HOME` and `PRJ_ROOT` |
| `--prj-root <path>` | set `PRJ_ROOT` before applying the environment |
| `<command> …` | apply the environment, then `exec` the command |
| `--` | end flag parsing |

Sourcing the file instead of executing it applies the environment and returns, which is the shape a
shell rc file needs.

There is no `--env-bin` flag. devshell uses it to put generated command scripts on `PATH`; v1
generates no commands, so the flag would have nothing to point at.

### Open Questions

1. `PATH` stripping covers the two directories the artifact itself prepends. A `hooks.enter` entry
   that prepends its own directory accumulates duplicates on every direnv reload.
   Non-blocking. Fixing it in the artifact would mean tracking every variable the hooks touch, which
   the hooks escape hatch exists to avoid.

## Evaluation & composition

### One evaluation per shell

`mkShell` builds a single `lib.evalModules` call: the caller's `modules`, preceded by a base module
that declares the options and hands `pkgs` to the rest.

```nix
mkShell = { pkgs, modules }:
  (lib.evalModules {
    modules = [ (baseModule pkgs) ] ++ modules;
  }).config;
```

`pkgs` reaches the description through `_module.args.pkgs`, so a description file is an ordinary
module function:

```nix
{ pkgs, ... }: {
  packages = [ pkgs.just ];
}
```

The alternative, `specialArgs`, would work equally well for a module list assembled in one place,
but composition here happens through `imports` inside those modules, and `_module.args` is what keeps
`pkgs` available to every module in the evaluation, imported or not, without threading a second
argument list through each file. It is also visible to the submodules nested under `env.<VAR>`,
which is the one place where that matters.

### Options are declared once

The base module owns every declaration: `name`, `packages`, `env`, `hooks.enter`,
`hooks.interactive`, `projectRoot`, `rootMarker`, `bashPackage`. Descriptions only set values, and
the option tree is therefore also the complete description vocabulary — there is nowhere else for a
setting to hide.

### `imports` is the only composition unit

A description is composed by importing other descriptions, exactly as modules compose anywhere else
in Nix:

```nix
{ ... }: {
  imports = [ ./shells/base.nix ];
  packages = [ pkgs.jq ];
}
```

Nothing else composes: no named parts, no priority numbers, no shell-valued function arguments. Base
shells, per-language fragments, and per-project overrides are all files that a description imports.

The merge behaviour follows from the option types:

- `packages` and the two hook lists concatenate, in import order and within each module in
  definition order.
- `env.<VAR>` merges per action, so a fragment can add `prefix` entries to a variable whose `set` it
  leaves alone, or override one action of a variable another module defined.
- Two modules assigning different values to the same non-list option, such as `name` or
  `projectRoot`, is a conflict the module system reports. Resolving it is the description author's
  call, with `lib.mkForce` or by not importing both.
- Import order is meaningful for `env` list actions: the first `prefix` entry on `PATH` wins, so an
  imported base shell's entries take precedence over the importing project's, which is the useful
  direction for tooling a base shell provides.

### Errors surface where the mistake is

Type errors, unknown options, and conflicts come from the module system, so the message names the
option and the file that set it. The one check the base module performs itself is the
path-value-without-`projectRoot` case, because no option type can express it; it is raised only when
such a value exists.

No option in v1 is silently defaulted to something surprising: `name`, `rootMarker`, and
`bashPackage` carry documented constants, and `projectRoot` is mandatory exactly when a path value
makes it necessary.

## Scope & non-goals

### What v1 covers

- Describing a shell with `packages`, `env`, and two hook phases.
- Per-variable `allowEval`, so an environment value built by shell code stays expressible without a hook.
- Composition through module `imports`, including shared base shells across projects.
- A single artifact entered by `nix develop`, `nix-shell`, direnv, or by running `$out/bin/<name>`.
- Project-relative path values, so a shell's store path does not depend on the checkout location.
- A hand-written README covering the options and the direnv caveats.

### What is deliberately absent

- **Commands and a help menu.** devshell's `commands.<name>` both exports a script and feeds a menu;
  v1 has neither, so a description adds executables through `packages` and behaviour through hooks.
  A generated command runner would bring its own flag handling, its own exit-code conventions, and
  its own direnv behaviour, none of which the shells described so far need.
- **Services, processes, language presets.** That is devenv's territory, and the reason its weight is
  not acceptable here.
- **TOML or any file format of its own.** A description is a Nix module, with no second syntax and no
  importer.
- **`profile.d` sourcing.** It delivers variables but silently drops the shell functions packages
  ship there, so its behaviour would depend on entry mode.
- **A setup hook, a `flakeApp` passthru, a `mkApp` helper.** The library exposes no flake-output
  vocabulary; `$out/bin/<name>` is the only entry point it contributes.
- **Generated option reference.** One README is the whole documentation surface.

### Deferred, not rejected

- The command registry and its menu, if the thin surface proves insufficient.
- Multi-statement or conditional environment setup, which the per-variable `allowEval` flag deliberately
  does not cover — that stays a hook's job.
- A setup hook for using the shell as a build input, which first requires splitting `env.bash` into a
  side-effect-free exports file and a shell-entry file.
- Migrating this repository's own `devShells.default` off `devshell`.

## Alternatives & Tradeoffs

### Plain attrset plus a merge helper

`mkDevShell { packages = [ ]; env = { }; }` with `lib.recursiveUpdate` and list concatenation needs
almost no code and no module vocabulary.

Rejected because it forfeits the thing this library exists to fix: without declared options there
are no types, no defaults, no per-file composition, and no error that names the offending file.
Precedence would also become this library's invention rather than a documented behaviour.

### drv-parts style part functions

A shell as a list of part functions folded into one description gives explicit, inspectable
composition and no option tree at all.

Rejected for the same reason plus one of its own: the fold rules would be ours to define, and the
documentation would still be hand-written prose, so the tradeoff buys composition semantics at the
cost of everything the module system provides for free.

### A flake-parts module

Declaring shells as `perSystem.devShells` would fit a flake-parts repo neatly.

Rejected because the point of the library is to be a reusable input for projects that may not use
flake-parts at all, and pulling it in to describe a shell is a heavier dependency than the problem
justifies.

### `pkgs.mkShell`

The shortest correct implementation: `mkShell` already sets the environment, runs a `shellHook`, and
is understood by `nix develop` and direnv.

Rejected because it drags stdenv's build environment into the shell and yields something that is only
a development shell. The `buildEnv` plus `env.bash` artifact is more code, but it produces one thing
that can be entered or executed, which is what keeps direnv, `nix develop`, and direct execution
sharing one implementation.

### Staying on devshell

devshell already does all of this, with a TOML front end and a `mkShell` that takes a configuration
attrset.

Rejected because its documentation describes the TOML configuration rather than the Nix interface, so
every change means reading `modules/devshell.nix`, and because its command registry, TOML importer,
and services layer are surface this repo does not use. Its artifact model, entrypoint flags, and
direnv handling are kept as the model to follow, which is why this spec cites them rather than
inventing alternatives.

### devenv

Wrong scale: services, processes, language presets, and its own state directory.

Rejected as a reference for scope, kept as evidence that the declarative shell idea works.

## Related artifacts

- `numtide/devshell` at `a67c0f87b63bcbdbdcb56785bec0205a2e3d6026` — the artifact model
  (`buildEnv`, `env.bash`, `entrypoint`, `mkNakedShell`), the entrypoint flag vocabulary, and the
  direnv-aware `PRJ_ROOT` handling are all taken from here. Its `modules/devshell.nix` is also the
  reference for what was deliberately left out.
- nix-direnv 3.2.0, `direnvrc` — establishes that the environment `nix print-dev-env` prints ends by
  evaluating the shell hook, which is why the hooks are reachable under direnv at all.
- `EXPLO-shell-shape.md` and `EXPLO-consumer-contract.md` in this directory — the settled decisions
  with the rejected candidates and their reasons, in more detail than this spec keeps.
- `nix/SPEC-DRAFT-wrapkit-system/SPEC.md` — the per-variable environment action model, reduced here
  to the actions a shell needs.
- nixpkgs' module system and `nixosOptionsDoc` — the evaluator, the option types, and the error
  messages this design relies on instead of reimplementing.
