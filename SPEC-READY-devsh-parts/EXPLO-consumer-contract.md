# consumer-contract — exploration

The public edge of the library: what a consuming flake writes, what `mkShell` accepts, what the
returned derivation exposes, and how `nix run` works without pulling in `flake-parts`.

## Findings

- devshell's public API is minimal at the flake level: `mkShell = configuration: (eval {
  inherit configuration; }).shell` plus `eval`, `fromTOML`, `modules-docs`, `docs`, `tests`,
  `mkNakedShell`. Only `mkShell` (and doctests) constitute the consumer contract.
- devshell's `mkShell` takes a **configuration**, not a list of modules, and `name` lives inside it
  as an option.
- devshell attaches a flake app to the derivation: `mkFlakeApp` produces
  `{ type = "app"; program = "<bin>"; }`, surfaced through `passthru.flakeApp`, so consumers spread
  it in (`apps.${system}.default = myShell.passthru.flakeApp;`) instead of the library knowing
  about flakes or systems.
- devshell's `hook` passthru is a setup hook: a derivation whose `setupHook` is
  `source <env.bash>`. stdenv sources any `nix-support/setup-hook` from a dependency listed in
  `nativeBuildInputs`/`buildInputs`, so the shell's env leaks into another derivation's builder —
  that is the entire relation, and it is only meaningful for building *other* derivations.
- Consequence of that being `env.bash`: the sourced file sets `PRJ_ROOT` (with a hard error when
  unresolvable), prepends to `PATH`, and runs hooks — none of which make sense inside a sandboxed
  builder, where there is no project root and hooks may assume an interactive-ish shell.
- `system` is absent from the contract once `pkgs` is a parameter: `pkgs.stdenv.hostPlatform.system`
  is derivable, and a flake app built from a derivation needs no separate system argument.

## Design crux

How thin can the exported surface be while still being usable from a plain (non-`flake-parts`)
flake, where the consumer must wire systems, pkgs, and apps by hand?

## Candidate directions

- (rejected) **Derivation carries its app** — `passthru.flakeApp` as devshell does. Rejected by the
  user: nothing app-shaped is exposed.
- (rejected) **`lib.mkApp` helper** — an explicit helper export. Rejected alongside the passthru;
  the library owns no flake-output vocabulary at all.
- (rejected) **`hook` passthru** — dropped; the build-sandbox mismatch recorded above is the reason.
- (active) **App via `$out/bin/<name>`** — the only remaining route: a consumer wanting `nix run`
  writes the app entry itself against `$out/bin/<name>`.

## Decisions

- (settled) **`mkShell` takes `{ pkgs, modules }`** — no `name` argument and no `system`; `name`
  is an option inside the module so it merges through `imports` like every other setting.
- (reversed) **The app rides on the derivation** — `passthru.flakeApp` was settled, then explicitly
  reversed: nothing app-shaped is exposed. The derivation's `$out/bin/<name>` is the only entry
  point; wiring `apps.*` is the consumer's business.
- (settled) **No setup hook** — `hook` is not exposed in v1; `env.bash` is a shell-entry file with
  `PRJ_ROOT` resolution and hook side effects, so it cannot be sourced in a sandbox without
  splitting the artifact first.
- (settled) **`pkgs` arrives via `_module.args.pkgs`** — modules write `{ pkgs, ... }`, the value is
  inherited by nested evaluations, and imported base shells need no special-args threading.
- (settled) **README covers options + direnv caveats only** — the coercion rules, the hooks-are-
  non-interactive-under-direnv note, and no `profile.d`; no apps recipe.
- (settled) **Passthru is `config` + `entrypoint`** — the evaluated option tree for tests and
  inspection, and the entrypoint path for consumers that want it directly.

## Open threads

- `config` passthru: the fully-evaluated option tree is promised, but is its shape stable enough
  to call an API (tests and debugging are the stated uses)?
- `entrypoint` passthru: worth exposing beyond what `$out/bin/<name>` already gives?
- README-only docs: what the README must cover for the surface to be usable without option docs
  (three options and their coercion rules, plus the direnv caveats from `shell-shape`, plus the
  hand-written `apps.<system>.default` recipe if `nix run` is to be documented at all).
