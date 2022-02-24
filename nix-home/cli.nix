{ config, pkgsChannels, lib, mybuilders, ... }:

let
  inherit (pkgsChannels) stable bleedingedge;
in {
  home.packages = [
    stable.neovim
    stable.rust-analyzer
    stable.sumneko-lua-language-server

    bleedingedge.zsh
    stable.exa # alternative ls, more colors!
    bleedingedge.bat # 'bleedingedge to have latest 'less' version I need
    stable.fd
    bleedingedge.fzf
    stable.git
    stable.git-lfs
    stable.gh  # github cli for view & operations
    bleedingedge.delta # for nice git diffs
    stable.jq
    bleedingedge.ripgrep
    stable.tree
    stable.just
    (stable.ranger.override { imagePreviewSupport = false; less = bleedingedge.less; })

    stable.htop
    bleedingedge.less # very-recent 'less' version I need for my key bindings
    stable.tmux
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
  ];
}
