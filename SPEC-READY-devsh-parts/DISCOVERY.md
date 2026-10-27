# devsh-parts Nix-native dev shell library

## Inputs

- **Name**: devsh-parts — a thin, Nix-native developer-shell description library.
- **Slug**: `devsh-parts`.
- **Problem**: `numtide/devshell` is consumed here through its Nix `mkShell` interface, but its
  documentation addresses the TOML configuration instead, so the Nix-level surface has to be
  rediscovered from `modules/devshell.nix` on every change. `devenv` solves the ergonomics but is
  far heavier than needed (services, processes, language presets). The need is a declarative shell
  description — packages, environment, hooks — that is Nix at every layer, reusable as a flake
  input by other projects, with a surface small enough to read in one sitting.
- **Inspirations**: `numtide/devshell` (its artifact model, entrypoint flags, direnv handling);
  `devenv` (rejected as scope reference, kept as feasibility reference); `flake-parts` and
  `drv-parts` (the "parts" in the name: module-based composition); `nix/SPEC-DRAFT-wrapkit-system`
  (the per-VAR environment action model); nixpkgs' module system and `nixosOptionsDoc`.

## Sources

- Exploration: inside this spec directory — `EXPLO-BRIEF.md` plus two frozen topics,
  `EXPLO-shell-shape.md` and `EXPLO-consumer-contract.md`. These hold the settled decisions and
  the rejected candidates with their reasons; the spec drafts from them rather than repeating the
  debate.
- Third-party source read during exploration: `numtide/devshell` at
  `a67c0f87b63bcbdbdcb56785bec0205a2e3d6026` (`default.nix`, `modules/devshell.nix`,
  `nix/mkNakedShell.nix`), and nix-direnv 3.2.0's `direnvrc`.

## Constraints

- The description surface stays at `packages`, `env`, `hooks` in v1. No commands, no services, no
  language presets, no TOML.
- Composition is the Nix module system: `lib.evalModules`, `imports`, `_module.args.pkgs`. No
  bespoke merge evaluator, no `flake-parts` dependency.
- The library exposes no flake-output vocabulary: no `flakeApp`, no `mkApp`, no setup hook.
- Documentation is a hand-written README covering the options and the direnv caveats.
- Out of scope: migrating this repo's own `flake.nix` off `devshell` (deferred, see
  `EXPLO-BRIEF.md` topic `repo-migration`), services/processes, language-specific option sets,
  replacing `kit-system`.

## Project-global docs

- None referenced. The user chose a standalone spec: terms (module, shell, artifact, entrypoint)
  are defined inside the spec rather than borrowing `nix/DESIGN_config_system.md` vocabulary, and
  `nix/kits/README.md` is not a normative reference.

