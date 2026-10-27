# devsh-parts — exploration brief

## Motivation

Context: `flake.nix` uses `numtide/devshell` for a single tiny default shell, and already carries
a `TO-EXPERIMENT(?)` note about `flake-parts`. The repo also has its own module machinery
(`nix/kit-system` + `nix/kits`) for tool configs.

Problem: the repo consumes `numtide/devshell` through its Nix `mkShell` interface, but devshell
documents its TOML configuration rather than that interface, so using it in Nix means reading
`modules/devshell.nix`. devenv is too heavy for the need. Wanted: a declarative way to describe a
dev shell — packages, env vars, scripts, hooks — that is Nix-native from top to bottom and
documented at the surface people use.

Scope: a reusable flake input usable by other projects, thin surface (no processes, no language
extras), keeping devshell's per-command description/category and generated help menu.

Out of scope: devenv parity (services/processes), language-specific option sets, replacing
kit-system.

## Topics

- (frozen) `shell-shape` — the declarative surface: option tree, evaluation mechanism, merge and composition semantics
- (frozen) `consumer-contract` — `mkShell` signature, returned derivation, passthru surface, `nix run` app
- (unexplored) `repo-migration` — moving this repo's default `devShells.default` off `devshell`; deferred by the user until devsh-parts exists
