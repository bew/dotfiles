# wrapped-drv-generator — exploration

## Findings

Every wrapped drv today is produced by `mypkglib.replaceBinsInPkg`: copy a package, drop its `bin/`, then `makeWrapper` one binary into the fresh `bin/`.

| toolkit | base pkg | bin | wrapper args | env option |
| --- | --- | --- | --- | --- |
| tmuxkit | `pkgs.tmux` | renamed via `binName` | `--add-flags "-f <cfgEntrypoint>"`, `--set TMUX_CONFIG_ENTRYPOINT`, `--prefix TERMINFO_DIRS : <pkg.terminfo>/share/terminfo`, per-env `--set`/`--set-default` | `env.<NAME>.{set,set-default}` — `nullOr str` submodule, no other actions |
| nvimkit | `pkgs.neovim` | renamed via `binName` | `--prefix PATH : <deps.bins>/bin`, `--set NVIM_APPNAME`, `--prefix XDG_CONFIG_DIRS`/`XDG_DATA_DIRS`, optional `--add-flags -u <init>` | `env.<NAME>` — plain `str` (`attrsOf str`) |
| zshkit | `pkgs.zsh` | `zsh` | `--set ZDOTDIR`, `--set ZSH_CONFIG_HASH`, `--set SHELL_CLI_ENV=<deps.bins>` | none — extras are `substitute`d into `.zshenv` at build time |

Takeaways:
- The env schema is per-toolkit and inconsistent (`{set,set-default}` vs plain `str`).
- Only `set`/`set-default` are modeled; `prefix` and `add-flags` are hand-emitted in each toolkit.
- nvimkit has two result variants (`toolPkg.standalone`, `toolPkg.configured`) built from one `makeNvimWrapperPkg`.
  tmuxkit and zshkit only expose `toolPkg.standalone`.
  That divergence is part of "unify wrapped-drv outputs".

## Design crux

The problem has two parts that are usually entangled, and should be split in the spec.
The wrapped-drv generator turns a (package, bin, env/arg spec) into a `makeWrapper` drv.
The env-override module system composes the env/arg spec from a commons plus scoped overrides.

## Decisions

- **The wrap target is a single bin** — the builder never uses `replaceBinsInPkg`/`copyFromPkg` (only one binary is generated). _(settled)_
- **`wrappedBin` accepts a path string or a derivation** — a derivation is resolved with `lib.getExe`. _(settled)_
- **`binName` is a `mkWrapkitBin` param** — it drives the `$out` layout: non-null (default derived) → `$out/bin/<binName>`, `null` → single-file `$out`. _(settled)_
- **`output` is built by assembling a `makeWrapper` argument list** from `env`, `flags`, and the process-control options, then building the wrapped drv. _(settled)_
- **Layout 2 (default) — `$out/bin/<binName>`** — the conventional package layout. _(settled)_

  ```nix
  output = runCommandLocal (binName or "wrapped-bin") { nativeBuildInputs = [ makeWrapper ]; } ''
    mkdir -p $out/bin
    makeWrapper ${wrappedBin} $out/bin/${binName} ${lib.escapeShellArgs wrapperArgs}
  '';
  ```

- **Layout 1 — `$out` is the executable file** — opted into with `binName = null`. _(settled)_

  ```nix
  output = runCommandLocal "wrapped-bin" { nativeBuildInputs = [ makeWrapper ]; } ''
    makeWrapper ${wrappedBin} $out ${lib.escapeShellArgs wrapperArgs}
  '';
  ```

- **Layout tradeoff** — Layout 2 keeps `binName` effective as the command name, composes into `PATH` environments, and resolves via `lib.getExe`; Layout 1 is minimal (one file), but the executable's on-disk name is the hash-prefixed drv name and it lives outside any `bin/`, so it cannot be added to `PATH` via `home.packages`/`buildEnv` and `lib.getExe` does not resolve it. Both layouts generate only one binary, so neither needs `replaceBinsInPkg`/`copyFromPkg`. _(settled)_

## Open threads

- How is the single-bin drv composed into a package (bins + config dirs) — a separate `mkWrapkitPkg`, or the toolkit's job? See `EXPLORATION-packaging-composition.md`.
