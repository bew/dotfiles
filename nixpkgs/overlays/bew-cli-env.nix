# This file must be in ~/.config/nixpkgs/overlays/
# Ref: https://nixos.org/manual/nixpkgs/stable/#chap-overlays

final: prev:

{
  # Ref: https://nixos.org/nixpkgs/manual/#sec-declarative-package-management
  bew-cli-env = prev.buildEnv {
    name = "bew-cli-env";
    paths = let p = prev; in [
      p.neovim
      p.rust-analyzer
      p.sumneko-lua-language-server

      p.fd
      p.fzf
      p.git
      p.git-lfs
      p.delta # for nice git diffs
      p.jq
      p.ripgrep
      p.tree
      p.zsh

      # When these are enabled, they can't find the terminfo of my arch terminal (urxvt) :/
      # p.htop
      # p.less
      # p.tmux
      # p.ncdu

      p.cloc
      p.httpie
      p.strace
      p.watchexec

      p.moreutils # for ts, and other nice tools https://joeyh.name/code/moreutils/

      # Nix tools
      p.nix-tree # TUI to browse the dependencies of a derivation
    ];
  };
}
