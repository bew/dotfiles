{ config, lib, pkgs, ... }:

let
  ty = lib.types;
  cfg = config;
  outs = cfg.outputs;
in {
  _class = "tool.nvim"; # type of nix module

  ID = "nvim-bew";
  package = pkgs.neovim.override {
    withPython3 = false;
    withRuby = false;
  };

  # NOTE: at the moment, all plugins are put in `opt` (need to be loaded with `:packadd <key>`)
  deps.plugins = {
    telescope-fzf-native = pkgs.vimPlugins.telescope-fzf-native-nvim;

    lazy-nvim = pkgs.vimPlugins.lazy-nvim;

    nvim-treesitter = pkgs.symlinkJoin {
      name = "config-${config.ID}-treesitter-parsers";
      paths = let
        tsPackage = pkgs.vimPlugins.nvim-treesitter;
        # REF: https://github.com/NixOS/nixpkgs/blob/master/pkgs/applications/editors/vim/plugins/nvim-treesitter/generated.nix
        # REF: https://github.com/nixos/nixpkgs/blob/master/pkgs/applications/editors/vim/plugins/nvim-treesitter/overrides.nix
        tsParsersPackage = (tsPackage.withPlugins (p: [
          # Grammars - important to have
          p.bash p.diff p.git_config p.git_rebase p.gitcommit p.gitignore p.hcl p.html p.ini
          p.javascript p.json p.just p.markdown p.markdown_inline p.nix p.python p.requirements
          p.rust p.sql p.terraform p.toml p.tsx p.yaml
          # p.nu # (not found 🤔)

          # Grammars - nice to have
          p.c p.css p.dot p.editorconfig p.gitattributes p.go p.helm p.http
          p.jq p.json5 p.make p.regex p.typescript p.typst p.xml
          # p.dockerfile (very broken 🙁)
          # p.tmux (very broken.. 🙁)
          #   https://github.com/Freed-Wu/tree-sitter-tmux/issues/2
          #   https://github.com/Freed-Wu/tree-sitter-tmux/issues/6

          # # Grammars - for maybe some day, maybe not..
          # p.cue p.gleam p.graphql p.jsonnet p.kdl p.nickel p.norg p.rego p.roc p.ron p.rst
          # p.strace p.sxhkdrc p.teal p.unison p.vue p.wit p.yuck p.zig
        ])).dependencies;
      in [ tsPackage tsParsersPackage ];
    };
  };

  # LSP Servers
  deps.bins = {
    # Lua
    lua-language-server.pkg = pkgs.lua-language-server;

    # python
    # note: the python pkg is in a separate option to make it easy to replace/override.
    python-lsp-server.extra.pyPkg = pkgs.python3;
    python-lsp-server.pkg = let
      pyPkg = cfg.deps.bins.python-lsp-server.extra.pyPkg;
    in pyPkg.withPackages (pp: [
      pp.python-lsp-server
      pp.python-lsp-ruff
      pp.pylsp-mypy
      # pp.python-lsp-isort (FIXME: not in nixpkgs yet..)
    ]);
    # /!\ These as independent LSP are not ready yet!..
    #     Let's continue with pylsp with ruff & mypy plugin for now..
    # ty.pkg = pkgs.ty;
    # ruff.pkg = pkgs.ruff;

    # rust
    rust-analyzer.pkg = pkgs.rust-analyzer;

    # YAML
    yaml-language-server.pkg = pkgs.yaml-language-server;

    # Terraform
    terraform-ls.pkg = pkgs.terraform-ls;
  };

  nvimDirSource = ./.;
  initFile = "init.lua";

  env.NVIM_BEW_MYPLUGINS_PATH = toString (cfg.lib.mkLink ../nvim-myplugins);
}
