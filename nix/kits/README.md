# Kits & tool kits

A **tool kit** is a [kit](../DESIGN_config_system.md) specialized for a CLI tool.
It is built with `newToolkit` in [./toolkits.nix](./toolkits.nix) — the registry of this repo's tool kits — on top of the tool-agnostic `kitsys` in [../kit-system](../kit-system).

Each toolkit bundles:
- the shared tool [base module](./kit-modules/toolkit-base.kit-module.nix)
- the `dynpaths` toolkit module, from the `dynpaths` flake input
- and the tool-specific base module

A **tool config** is the evaluation of a toolkit with a config module:
```nix
toolconfigs.zsh-bew = toolkits.zshkit.eval {
  pkgs = bleedingedgePkgs;
  config = ./zsh/bew-config.zshkit-module.nix;
};
```

## Naming conventions

| Role | Pattern | Example |
| --- | --- | --- |
| Tool-specific base module | `<tool>kit-base.toolkit-module.nix` | `zshkit-base.toolkit-module.nix` |
| Tool config module | `<configName>-config.<toolkit>-module.nix` | `bew-config.zshkit-module.nix` |
