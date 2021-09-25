{ config, ... }:

let
  inherit (config.pkgsChannels) stable bleedingedge;
in {
  home.packages = [
    bleedingedge.neovim
    bleedingedge.rust-analyzer
    stable.sumneko-lua-language-server

    stable.fd
    bleedingedge.fzf
    stable.git
    stable.git-lfs
    bleedingedge.delta # for nice git diffs
    stable.jq
    bleedingedge.ripgrep
    stable.tree
    bleedingedge.zsh

    # When these are enabled, they can't find the terminfo of my arch terminal (urxvt) :/
    # stable.htop
    # stable.less
    # stable.tmux
    # stable.ncdu

    stable.cloc
    stable.httpie
    stable.strace
    stable.watchexec

    stable.moreutils # for ts, and other nice tools https://joeyh.name/code/moreutils/
    stable.gron # to have grep-able json <3

    stable.chafa # crazy cool img/gif terminal viewer
    # Best alias: chafa -c 256 --fg-only (--size 70x70) --symbols braille YOUR_GIF

    # Nix tools
    stable.nix-tree # TUI to browse the dependencies of a derivation (https://github.com/utdemir/nix-tree)
    stable.nix-diff # CLI to explain why 2 derivations differ (https://github.com/Gabriel439/nix-diff)
    stable.nixfmt # a Nix formatter (more at https://github.com/nix-community/nixpkgs-fmt#formatters)
  ];
}
