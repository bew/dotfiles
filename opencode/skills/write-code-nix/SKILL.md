---
name: write-code-nix
description: |
  Nix code writing guidelines: expression files, derivations, builder idioms, and verification.
  Always load when asked to draft/write/edit/refactor/review Nix code:
  flake.nix, *.nix, derivation/package definitions, or config-as-code written in Nix.
metadata:
  maintainers: [bew]
---

## Goal

Write idiomatic Nix code that evaluates and builds, building on generic conventions.

REQUIRES: load `write-code-generic` skill first.

NOTE: This skill covers general Nix expression files and reusable module option conventions.
It will later expand with dedicated pages for other Nix areas:
Nix packaging (derivations), flake-related topics, etc.

Nix is an expression language — there is no module/script split.
Every file is an expression; the last expression is the file's value.
All files are module-like: generic module rules apply, script rules are N/A.

## Rules

- File is an expression; the last expression in the file is its value.
- Pass dependencies via curried function args: `{ pkgs, lib, ... }:`.
  Destructure the args you use; keep `...` when more may be passed.
- Use `? default` for optional args with defaults.
- For `let ... in` bindings: Comment non-obvious bindings; skip comments on self-evident ones.
- Use `inherit x;` and `inherit (parent) a b;` to reuse bindings.
- Interpolate values into strings with `${expr}`.
- Use `''...''` for multi-line / indented strings — leading whitespace is stripped.
- Escape literal `$` in `''...''` as `\${`. Required when the string embeds shell code,
  where `$var`, `${var}`, and `$(cmd)` must survive to run in the build phase.
- Wrap paths interpolated into shell strings in `lib.escapeShellArg`.
  Never splice a store path into a shell snippet unescaped.
- Derive packages with the standard builders:
  `buildEnv`, `runCommandLocal`, `symlinkJoin`, `buildPythonApplication`, `buildGoModule`, etc.
  Prefer them over raw `stdenv.mkDerivation`.
- Sync package identity: `pname` (kebab-case) + `version`. No `name` except for non-package
  derivations (e.g. a `buildEnv` target).
- Set `meta.mainProgram` (the bin name the package exposes) and `meta.platforms`
  (e.g. `lib.platforms.unix`).
- Expose reusable packages through `callPackage ./path { }`.
  The callPackage function's curried args become its dependencies, injected by the caller.

## Guidelines

- For a derivation that only ships binaries: `runCommandLocal` that `mkdir -p $out/bin`
  and `ln -s` only the needed bins. Set `meta.mainProgram`.
- Use `lib.makeBinPath` and `lib.getExe` to reference tools in build phases.
  Do not hand-build PATH strings.
- Aggregate a developer profile with `pkgs.buildEnv { name = "..."; paths = [...]; }`
  listing the tools the profile should expose.

## Reusable modules

For a Nix module that declares its own options:

- Always define `ty = lib.types` binding, use it in all option types
- Define `cfg = config.<root>` binding when the declared options share a root owned by this module

Example module:
```nix
{ config, lib, ... }:

let
  ty = lib.types;
  cfg = config.foo;
in {
  options {
    foo.enable = lib.mkEnableOption "my super feature";
    foo.bar = lib.mkOption {
      description = ''some description'';
      type = ty.enum ["hello" "world"];
    };
  };
  config = lib.mkIf cfg.enable {
    something.being.configured = cfg.bar;
  };
}
```

## Verify

Run `nix-instantiate --parse <file>.nix` yourself to quickly verify syntax.

For the rest, ASK the user before running; they are heavier and may need network/build:
1. `nix build .#<attr>` — build a package attribute.
2. `nix flake check` — full flake checks.

Do NOT auto-run the heavier checks. Report status and let the user decide.
Do NOT use `nixfmt` unless explicitly requested by user.

## Testing

No Nix test skill exists in this setup.
Verification is the `Verify` ladder above.
If tests or flake checks are wanted (e.g. `nix-unit`, a `checks` output),
ask the user how to structure them before writing any.

## Reference docs

Do NOT fetch the Nix and nixpkgs manual pages unless asked — they are big and slow to load.
The `nix.dev` site is fine to search when you need it.
- `https://nix.dev/` — tutorials and reference. OK to search when needed.
- Nix manual: `https://nix.dev/manual/nix/latest/` — BIG, do not fetch unless asked.
- nixpkgs manual: `https://nixos.org/manual/nixpkgs/stable/` — BIG, do not fetch unless asked.
