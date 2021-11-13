{ config, ... }:

let
  inherit (config.pkgsChannels) stable bleedingedge;
in {
  home.packages = [
    bleedingedge.neovim
    bleedingedge.rust-analyzer
    stable.sumneko-lua-language-server

    stable.exa # alternative ls, more colors!
    bleedingedge.bat # use bleedingedge version, same as 'less' below (to have new 'less' with the options I want!)
    stable.fd
    bleedingedge.fzf
    stable.git
    stable.git-lfs
    bleedingedge.delta # for nice git diffs
    stable.jq
    bleedingedge.ripgrep
    stable.tree
    bleedingedge.zsh

    stable.htop
    bleedingedge.less # NOTE: need at least v283 to support LESSKEYIN env var
    stable.tmux
    stable.ncdu

    stable.cloc
    stable.httpie
    stable.strace
    stable.watchexec

    stable.moreutils # for ts, and other nice tools https://joeyh.name/code/moreutils/
    stable.gron # to have grep-able json <3
    stable.diffoscopeMinimal # In-depth comparison of files, archives, and directories.

    bleedingedge.chafa # crazy cool img/gif terminal viewer
    # Best alias: chafa -c 256 --fg-only (--size 70x70) --symbols braille YOUR_GIF

    # Nix tools
    stable.nix-tree # TUI to browse the dependencies of a derivation (https://github.com/utdemir/nix-tree)
    stable.nix-diff # CLI to explain why 2 derivations differ (https://github.com/Gabriel439/nix-diff)
    stable.nixfmt # a Nix formatter (more at https://github.com/nix-community/nixpkgs-fmt#formatters)
    # stable.nix-update # Swiss-knife for updating nix packages
  ];
}
