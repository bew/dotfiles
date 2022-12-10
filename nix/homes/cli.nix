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

  zshHomeModule = let
    zdotdir = (myPkgs.zsh-bew-zdotdir.override {
      fzf = groups.fzf-bins.fzf-bew; # make sure to use fzf-bew with specific fzf version
    });
  in {
    imports = [
      # Setup minimal bash config to proxy to zsh when SHLVL==1 and interactive
      ../../bash_minimal/proxy_to_zsh.home-module.nix
    ];
    home.packages = [ bleedingedge.zsh ];
    home.file.".zshrc".text = ''
      ZDOTDIR=${zdotdir}
      source ${zdotdir}/.zshrc
    '';
    home.file.".zshenv".text = ''
      source ${zdotdir}/.zshenv
    '';
  };

in {
  imports = [
    zshHomeModule
  ];

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

    stable.less

    stable.ncdu
    stable.htop
    stable.dogdns # nicer `dig`

    stable.jless # less for JSON
    stable.xsv # Fast toolkit to slice through CSV files (kinda sql-like)

    stable.ansifilter # Convert text with ANSI seqs to other formats (e.g: remove them)
    stable.cloc
    stable.httpie
    stable.strace
    stable.entr

    stable.units # gnu's unit converter, has MANY units (https://www.gnu.org/software/units/)
    # Best alias: units -1 --compact FROM-UNIT TO-UNIT

    stable.moreutils # for ts, and other nice tools https://joeyh.name/code/moreutils/
    stable.gron # to have grep-able json <3
    stable.diffoscopeMinimal # In-depth comparison of files, archives, and directories.

    stable.chafa # crazy cool img/gif terminal viewer
    # Best alias: chafa -c 256 --fg-only (--size 70x70) --symbols braille YOUR_GIF
    stable.translate-shell

    # Languages
    # NOTE: Compilers, interpreter shouldn't really be made available in a global way..
    #       Goes a bit against Nix-motto to have well defined dependencies, per-projects.
    # => Could still be nice-to-have for one-of tests/experiments...
    #    * Could make these available through a custom shell I need to launch?
    #      (or a kind of shell module to enable)
    #      With an explicit name like `shell-with-languages-for-ad-hoc-experimenting`
    #      (FIXME: need a shorter name...)
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
    (mybuilders.linkBins "some-nix-tools" {
      # TUI to browse the dependencies of a derivation (https://github.com/utdemir/nix-tree)
      nix-explore = "${stable.nix-tree}/bin/nix-tree";
      # CLI to explain why 2 derivations differ (https://github.com/Gabriel439/nix-diff)
      nix-diff-drv = "${stable.nix-diff}/bin/nix-diff";
    })
    stable.nixfmt # a Nix formatter (more at https://github.com/nix-community/nixpkgs-fmt#formatters)
    # stable.nix-update # Swiss-knife for updating nix packages
    # TODO: add nix-index!
  ];
}
