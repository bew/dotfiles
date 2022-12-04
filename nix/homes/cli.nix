{ config, pkgsChannels, lib, mybuilders, flakeInputs, system, ... }:

let
  inherit (pkgsChannels) backbone stable bleedingedge myPkgs;

  neovim-minimal = let pkgs = stable; in pkgs.neovim.override {
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

        nnoremap Y yy
        nnoremap <M-s> :w<cr>
        inoremap <M-s> <esc>:w<cr>
        nnoremap § :nohl<cr>
        nnoremap <M-a> gT
        nnoremap <M-z> gt
        nnoremap Q :q<cr>

        nnoremap U <C-r>

        nnoremap <C-h> <C-w>h
        nnoremap <C-j> <C-w>j
        nnoremap <C-k> <C-w>k
        nnoremap <C-l> <C-w>l

        cnoremap <M-k> <Up>
        cnoremap <M-j> <Down>

        source ${./../../nvim/colors/bew256-dark.vim}
      '';
      packages.myVimPackage = with pkgs.vimPlugins; {
        start = [
          vim-nix
        ];
      };
    };
  };

  groups.editor-bins = {
    nvim-minimal = neovim-minimal;
  };

  groups.fzf-bins = let fzf = bleedingedge.fzf; in {
    inherit fzf; # for normal bin + man
    fzf-bew = myPkgs.fzf-bew.override { inherit fzf; };
  };

  linkBinsForGroup = binsGroup: targetBinName:
    mybuilders.linkBins "${targetBinName}-bins"
      (lib.mapAttrsToList
        (binName: pkg: { name = binName; path = "${pkg}/bin/${targetBinName}"; })
        binsGroup);

in

lib.mkMerge [
  # Zsh mini module
  (let
    zdotdir = (myPkgs.zsh-bew-zdotdir.override {
      fzf = groups.fzf-bins.fzf-bew; # make sure to use fzf-bew with specific fzf version
    });
  in {
    home.packages = [ bleedingedge.zsh ];
    home.file.".zshrc".text = ''
      ZDOTDIR=${zdotdir}
      source ${zdotdir}/.zshrc
    '';
    home.file.".zshenv".text = ''
      source ${zdotdir}/.zshenv
    '';
  })

  {
    home.packages = [
      # packages on backbone channel, upgrades less often
      backbone.tmux

      #stable.neovim
      #stable.rust-analyzer
      neovim-minimal

      (linkBinsForGroup groups.fzf-bins "fzf")

      stable.exa # alternative ls, more colors!
      stable.bat
      stable.fd
      stable.git
      stable.git-lfs
      stable.gh  # github cli for view & operations
      bleedingedge.delta # for nice git diffs
      stable.jq
      stable.yq
      flakeInputs.binHtmlq.packages.${system}.htmlq
      bleedingedge.ripgrep
      stable.tree
      stable.just
      (stable.ranger.override { imagePreviewSupport = false; })

      stable.htop
      stable.less
      stable.jless # less for JSON
      stable.ncdu

      stable.ansifilter # Convert text with ANSI seqs to other formats (e.g: remove them)
      stable.cloc
      stable.httpie
      stable.strace
      stable.watchexec

      stable.moreutils # for ts, and other nice tools https://joeyh.name/code/moreutils/
      stable.gron # to have grep-able json <3
      stable.diffoscopeMinimal # In-depth comparison of files, archives, and directories.

      stable.chafa # crazy cool img/gif terminal viewer
      # Best alias: chafa -c 256 --fg-only (--size 70x70) --symbols braille YOUR_GIF
      stable.translate-shell

      # Languages
      stable.python3
      (let
        # Ref: https://github.com/NixOS/nixpkgs/pull/151253 (my PR to reduce ipython closure size)
        pyPkg = stable.python3;
        ipython-minimal = pyPkg.pkgs.ipython.override {
          matplotlib-inline = pyPkg.pkgs.matplotlib-inline.overrideAttrs (oldAttrs: {
            propagatedBuildInputs = (lib.remove pyPkg.pkgs.matplotlib oldAttrs.propagatedBuildInputs);
          });
        };
      in mybuilders.linkSingleBin "${ipython-minimal}/bin/ipython")

      (let androidPkgs = stable.androidenv.androidPkgs_9_0;
      in mybuilders.linkBins "android-tools-bins" [
        "${androidPkgs.platform-tools}/bin/adb"
        "${androidPkgs.platform-tools}/bin/fastboot"
      ])

      # Nix tools
      stable.nix-tree # TUI to browse the dependencies of a derivation (https://github.com/utdemir/nix-tree)
      stable.nix-diff # CLI to explain why 2 derivations differ (https://github.com/Gabriel439/nix-diff)
      stable.nixfmt # a Nix formatter (more at https://github.com/nix-community/nixpkgs-fmt#formatters)
      # stable.nix-update # Swiss-knife for updating nix packages
      # TODO: add nix-index!
    ];
  }
]
