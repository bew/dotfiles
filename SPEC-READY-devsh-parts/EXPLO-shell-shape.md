# shell-shape — exploration

What a shell description actually looks like in Nix: the option tree the user writes, how it is
evaluated, and how several descriptions merge into one shell. This is where "much simpler
devenv, minus the TOML" is either won or lost.

## Findings

- Constraint from repo recon: two declarative neighbours already exist — `flake-parts` as a
  considered option, and the in-house `kit-system`/`kits` module mechanism.
- User settled: devsh-parts is on its own (not built on, nor a generalisation of, kit-system).
- User settled: surface is thin — packages, env vars, scripts, hooks only.
- User settled: the command registry with per-command description/category and a generated help
  menu must survive from devshell. (Later superseded — see Decisions.)
- devshell conflates commands and scripts: every `commands.<name>` entry becomes both a script on
  `PATH` and a menu line. That conflation is a candidate to keep (one tree) or split (two trees).
  Moot for v1: no commands.
- The docs complaint is addressable by the evaluation mechanism itself: declared options with
  types and descriptions can be rendered to documentation (`pkgs.nixosOptionsDoc`) instead of
  being hand-written prose. devshell already does this (`modules-docs` → mdBook), so its real
  weakness is *usage* docs, not the option reference.
- devshell does **not** use `pkgs.mkShell`. It builds a `buildEnv` of the packages with
  `env.bash` + `entrypoint` injected, then wraps it in a raw `builtins.derivation` with a
  hand-written `naked-stdenv` whose `shellHook` sources `$profile/env.bash`, plus a `runHook`
  trampoline for `nix-shell`. Stated payoff: one artifact usable as `nix-build`, `nix-shell`,
  flake app (`nix run`), direnv, and a setup hook, with none of stdenv's env noise.
- devshell's `pkgs` is its own: derived from `nixpkgs.legacyPackages.${system}` with its own
  lock. That means a consumer project ends up with two nixpkgs (one for the shell, one for the
  build) — the argument for taking `pkgs` as a parameter instead.
- devshell's env layer handles direnv explicitly: `PRJ_ROOT=$PWD` when `DIRENV_IN_ENVRC = 1`, the
  motd printed immediately under direnv and otherwise deferred via `PROMPT_COMMAND`,
  `DEVSHELL_NO_MOTD=1` as the escape hatch.
- `shellHook` **is** direnv-compatible: `nix print-dev-env` ends its output with
  `eval "${shellHook:-}"`, and nix-direnv (3.2.0) captures that stdout as `flake-profile.rc` and
  evals it. Consequence: the hook runs on every direnv load/reload, in a non-interactive bash,
  and its output lands on `cd` rather than at shell start. It must therefore be idempotent and
  quiet.
- `profile.d` sourcing is asymmetric under direnv: direnv runs the envrc in a bash
  subprocess and exports only the environment diff (direnv issue #73, open), so exported vars
  survive (asdf's `ASDF_DIR`/PATH) while shell functions do not (`conda activate`, autojump's
  `j`, broot's `br`, nix-index's hook). Same reasoning applies to anything function-shaped.
- nixpkgs packages install `etc/profile.d` for two reasons: PATH/var setup (`asdf-vm`, `conda`)
  and shell functions (`autojump`, `broot`, `wezterm`, `flatpak`, `openpbs`, `undistract-me`,
  `nix-index`, `fish`); `gawk` ships a `setup-hook.sh` instead.
- Any design where a hook is the mechanism inherits those direnv constraints; a banner or menu
  needs the `DIRENV_IN_ENVRC`-aware treatment devshell uses.

## Design crux

Does "parts" mean a real module system, or just a merge convention? Everything downstream —
typed defaults, generated docs, splitting a shell across files, reusing a base shell — follows
from that single choice. The cheap answer (a `recursiveUpdate` helper) is simple but forfeits
the docs fix; the heavy answer (a module evaluator) risks becoming devenv again.

## Candidate directions

- (active) **B — plain attrset + explicit merge helper**: `mkDevShell { packages = []; env = {}; }`
  with list concatenation and attrset union, no option declarations. Pro: minimal, zero learning
  curve, tiny code. Con: no types, no defaults, no docs, unclear precedence when merging.
- (active) **C — drv-parts style**: a shell is a list of part-functions
  (`{ pkgs, lib, ... }: { … }`) folded into one description, with the fold rules owned by us.
  Pro: composition is explicit and inspectable; no option tree. Con: we own the fold semantics,
  and docs still have to be written by hand.
- (rejected) **B and C** — both lose to A: without declared options there are no types, no
  defaults, no generated docs, and precedence becomes our invention. A settled it.
- (rejected) **flake-parts module** — dropped: the user wants an independent, reusable flake
  input, and pulling flake-parts in for a dev-shell library is a heavier dependency than the
  problem justifies.

## Decisions

- (settled) **Reusable flake input** — devsh-parts is designed for consumption by other projects,
  self-contained and documented, not a private helper for this repo.
- (settled) **Independent of kit-system** — its own mechanism; kits keep handling tool configs.
- (settled) **Thin surface** — packages, env vars, scripts, hooks. No processes/services, no
  language extras.
- (superseded) **Keep the command registry** — per-command description/category, with a generated
  help menu shown on shell entry. Superseded by "no commands in v1".
- (settled) **Typed options via `lib.evalModules`** — candidate A; nixpkgs' module system owns
  defaults, merging, `imports`, and doc generation. No bespoke evaluator.
- (settled) **`imports` as the only composition unit** — no named parts; base-shell reuse and
  file splitting both ride on standard module imports.
- (settled) **No commands in v1** — the described surface is `packages`, `env`, `hooks`. The
  command registry and its help menu move out of v1 entirely, not merely simplified.
- (settled) **Caller passes `pkgs`** — `mkShell` takes the package set explicitly, so the shell
  uses the project's nixpkgs instead of pulling a second one from the library's own lock.
- (settled) **devshell-style artifact** — build a `buildEnv` holding `env.bash` + an
  `entrypoint`, wrapped in a raw `builtins.derivation` with a hand-written stdenv/setup, rather
  than `pkgs.mkShell`. Chosen for the `nix run` app, setup-hook reuse, and clean env.
- (settled) **Two hook phases** — `enter` (whenever the env is applied) and `interactive`
  (interactive shells only). No `exit` phase: nothing runs it reliably.
- (settled) **`packages` takes derivations only** — no string resolution against `pkgs`.
- (settled) **Entrypoint keeps devshell's flags** — `--pure`, `--prj-root`, `-h` parsing carried
  over rather than trimmed. Amended during drafting: `--env-bin` is dropped, since it existed to
  put devshell's generated command scripts on `PATH` and v1 generates none.
- (settled) **Hooks are `listOf str`** — per-entry addressing (`mkBefore` a single item), order
  from `imports`, no heredoc/quoting coupling across entries. Cost accepted: users write
  `[ ''…'' ]` rather than a bare string, unlike `shellHook`/`enterShell` precedent.
- (settled) **Reduced wrapkit-style env actions** — `env.<VAR>` is a submodule of `sep`, `set`,
  `set-default`, `unset`, `prefix`, `suffix`, with `coercedTo str (v: { set = v; })` so
  `env.FOO = "bar"` stays terse. `*-each` and `*-contents` dropped as makeWrapper-only.
  Emitted in a fixed order into `env.bash`. A per-variable `allowEval` flag was added later, during
  spec drafting, so action values can be emitted as shell code instead of literals.- (settled) **`name` and `bashPackage` stay; `meta` goes** — the entrypoint symlink, store path and
  prompts need `name`; the interactive shell needs a choosable bash; `meta`'s `mainProgram` can
  default to `name`, and description/licence on a dev shell buy nothing.
- (settled) **Env emission order is `unset → set-default → set → prefix → suffix`** — read as
  "clear inherited, fill if absent, assign, then prepend/append onto whatever value exists", so
  `set` + `prefix` is a PATH-style idiom rather than a conflict. `unset` + `set` is redundant but
  legal; documented, not enforced.
- (settled) **PATH is stripped before prepending** — devshell's `${PATH#${bashBin}:}` trick, so
  repeated direnv reloads do not grow the variable.
- (settled) **No `profile.d` sourcing** — the loop is not implemented. The direnv asymmetry
  (exported vars survive, functions do not) makes its behaviour mode-dependent, so the shell
  carries no implicit sourcing; users add what they need in `hooks.enter`.
- (settled) **PRJ_ROOT is set on entry** — devshell's behaviour: `PRJ_ROOT=$PWD` when
  `IN_NIX_SHELL` is set or `DIRENV_IN_ENVRC = 1`, a configurable fallback otherwise, and a hard
  error when it cannot be resolved.

## Open threads

- Evaluation mechanism: A, B, or C (pending user).
- Commands and the help menu: parked for v1. Revisit only if the thin surface proves insufficient.
- Shell name and metadata: devshell has `name`, `meta`, `bashPackage`, `load_profiles`. Which of
  these survive the thinning? `name` is needed for the entrypoint; the rest are candidates to drop.
- env action ordering detail: the fixed order (`set`, `set-default`, `unset`, `prefix`, `suffix`)
  needs a decision on where inherited-vs-set conflicts land when both a `set` and a `prefix` apply
  to the same VAR.
- `env.bash` details not yet pinned: whether `PATH` is manipulated with the same
  `strip-suffixes` trick devshell uses to avoid duplicate entries on re-entry.
- Next topic, not yet opened: the consumer contract — `mkShell`-only entry point (settled), how
  `pkgs` and `system` are threaded, the returned derivation's passthru (`hook`, `entrypoint`,
  `config`), and README-only docs.
