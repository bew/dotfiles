{ config, lib, pkgs, ... }:

let
  ty = lib.types;
  cfg = config;
  outs = cfg.outputs;
in {
  ID = "nvim-wip";
  package = pkgs.neovim.override {
    withPython3 = false;
    withRuby = false;
  };

  # TODO: expose an environment with:
  # - treesitter parsers (or enough to compile/install them?)
  # - plugins 🤔

  deps.lspServers = {
    # python
    python-lsp-server.pkg = pkgs.python3.withPackages (pp: [
      pp.python-lsp-server
      pp.python-lsp-ruff
      pp.pylsp-mypy
      # pp.python-lsp-isort (not in nixpkgs yet..)
    ]);

    # rust
    rust-analyzer.pkg = pkgs.rust-analyzer;
  };
  deps.bins = cfg.deps.lspServers;

  nvimDirSource = ./.;
  initFile = "init.lua";

  env.NVIM_BEW_MYPLUGINS_PATH = toString (cfg.lib.mkLink ../nvim-myplugins);
}
