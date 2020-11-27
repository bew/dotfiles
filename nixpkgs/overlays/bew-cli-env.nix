# This file must be in ~/.config/nixpkgs/overlays/
# Ref: https://nixos.org/manual/nixpkgs/stable/#chap-overlays

self: super:

{
  # Ref: https://nixos.org/nixpkgs/manual/#sec-declarative-package-management
  bew-cli-env = super.buildEnv {
    name = "bew-cli-env";
    paths = let p = super; in [
      p.neovim

      p.fd
      p.fzf
      p.git
      p.git-lfs
      p.htop
      p.jq
      # p.less # When enabled, less can't find the terminfo of my arch terminal (urxvt) :/
      p.ripgrep
      p.tmux
      p.tree
      p.zsh

      p.cloc
      p.httpie
      p.ncdu
      p.strace
      p.watchexec
    ] ++ [ # Add packages from my overlays
      self.delta-bin
    ];
  };
}
