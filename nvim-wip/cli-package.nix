{
  pkgs,
  writeShellScriptBin,
  mybuilders,
  lib,

  vimPlugins,
  neovim,
}:

let

  nvim-base = neovim.override {
    # NOTE: nixpkgs.neovim is a drv using 'legacyWrapper' function:
    # defined in: <nixpkgs>/pkgs/applications/editors/neovim/utils.nix
    # used in: <nixpkgs>/pkgs/top-level/all-packages.nix for 'wrapNeovim' function
    # ---
    # python3 & ruby providers are enabled by default..
    # => I think I won't need them, I want to have vimscript or Lua based plugins ONLY
    withPython3 = false;
    withRuby = false;
  };

  # TODO: expose an environment with:
  # - treesitter parsers (or enough to compile/install them?)
  # - lsp servers
  lspDeps = [
    # python
    (pkgs.python3.withPackages (pp: [
      pp.python-lsp-server
      pp.python-lsp-ruff
      pp.pylsp-mypy
      # pp.python-lsp-isort (not in nixpkgs yet..)
    ]))

    # rust
    pkgs.rust-analyzer
  ];

  nvim-wip = writeShellScriptBin "nvim-wip" ''
    export PATH=$PATH:${
      # FIXME: should use bleedingedge for these deps 👀
      lib.makeBinPath lspDeps
    }
    export NVIM_APPNAME=nvim-wip
    export NVIM_BEW_MYPLUGINS_PATH=${./../nvim-myplugins} # config specific (!! not editable :/)
    exec ${lib.getExe nvim-base} "$@"
  '';

in {
  pkgs.nvim-wip-bin = nvim-wip;

  homeModules.nvim-bew = { config, pkgs, ... }: {
    xdg.configFile."nvim-wip".source = config.dyndots.mkLink ./.;
    home.packages = [ nvim-wip ];
  };
}
