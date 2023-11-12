{
  writeShellScriptBin,
  mybuilders,
  lib,

  vimPlugins,
  neovim,
}:

let

  nvim-base = neovim.override {
    # NOTE: nixpkgs.neovim is a drv using 'legacyWrapper' function:
    # defined in: nixpkgs-repo/pkgs/applications/editors/neovim/utils.nix
    # used in: nixpkgs-repo/pkgs/top-level/all-packages.nix for 'wrapNeovim' function
    # ---
    # python3 & ruby providers are enabled by default..
    # => I think I won't need them, I want to have vimscript or Lua based plugins ONLY
    withPython3 = false;
    withRuby = false;
  };

  nvim-minimal = nvim-base.override {
    configure = {
      # TODO: make this a proper nvim plugin dir 'myMinimalNvimConfig'
      customRC = /* vim */ ''
        set shiftwidth=2 expandtab
        set mouse=nv
        set iskeyword+=-
        set ignorecase smartcase
        set smartindent
        set number relativenumber
        set cursorline
        " mappings
        nnoremap Y yy
        nnoremap <M-s> :w<cr>
        inoremap <M-s> <esc>:w<cr>
        nnoremap § :nohl<cr>
        nnoremap <M-a> gT
        nnoremap <M-z> gt
        nnoremap Q :q<cr>
        " logical redo
        nnoremap U <C-r>
        " window navigation
        nnoremap <C-h> <C-w>h
        nnoremap <C-j> <C-w>j
        nnoremap <C-k> <C-w>k
        nnoremap <C-l> <C-w>l
        " basic cmdline navigation
        cnoremap <M-k> <Up>
        cnoremap <M-j> <Down>
        " colorscheme
        source ${./colors/bew256-dark.vim}
      '';
    };
  };

  nvim-original = mybuilders.replaceBinsInPkg {
    # The original nvim Nix package, with another bin name
    name = "nvim-original";
    copyFromPkg = nvim-base;
    bins = { nvim-original = lib.getExe nvim-base; };
  };

  # TODO: expose an environment with:
  # - treesitter parsers
  # - lsp servers

in {
  packages = {
    inherit nvim-original nvim-minimal;
  };
  homeModules.nvim-base-bins = { config, ... }: {
    home.packages = [
      (mybuilders.linkBins "nvim-base-bins" {
        inherit nvim-original nvim-minimal;
      })
    ];
  };
  homeModules.nvim-bew = { config, ... }: let
    # My WIP config, directly accessible as `nvim`
    # Use `nvim-minimal` if all is broken!
    nvim-wip = writeShellScriptBin "nvim-wip" ''
      export NVIM_APPNAME=nvim-wip
      export NVIM_BEW_MYPLUGINS_PATH=${config.dyndots.mkLink ./../nvim-myplugins} # config specific
      exec ${lib.getExe nvim-base} "$@"
    '';
  in {
    xdg.configFile."nvim-wip".source = config.dyndots.mkLink ./.;
    home.packages = [
      (mybuilders.linkBins "nvim-wip-and-default" {
        inherit nvim-wip;
        nvim = nvim-wip;
      })
    ];
  };
}
