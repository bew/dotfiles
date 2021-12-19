{ config, pkgsChannels, lib, ... }:

let
  inherit (pkgsChannels) stable bleedingedge;

  # Builds a derivation that only has a link to a binary in another derivation.
  # Can be used to rename a binary and allow multiple version of the same software
  # in the same environment.
  linkSingleBin = binName: binPath:
    stable.runCommandLocal "${binName}-bin-link" { } ''
      link_path=$out/bin/${lib.escapeShellArg binName}
      mkdir -p $out/bin
      ln -s ${lib.escapeShellArg binPath} "$link_path"
      # NOTE: a symlink to an executable is automatically executable
    '';

in {
  home.packages = [
    stable.neovim
    stable.rust-analyzer
    stable.sumneko-lua-language-server

    stable.exa # alternative ls, more colors!
    bleedingedge.bat # use bleedingedge version, same as 'less' below (to have new 'less' with the options I want!)
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
    bleedingedge.zsh

    stable.htop
    bleedingedge.less # NOTE: need at least v283 to support LESSKEYIN env var
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
    in linkSingleBin "ipython" "${ipython-minimal}/bin/ipython")

    # Nix tools
    stable.nix-tree # TUI to browse the dependencies of a derivation (https://github.com/utdemir/nix-tree)
    stable.nix-diff # CLI to explain why 2 derivations differ (https://github.com/Gabriel439/nix-diff)
    stable.nixfmt # a Nix formatter (more at https://github.com/nix-community/nixpkgs-fmt#formatters)
    # stable.nix-update # Swiss-knife for updating nix packages
  ];
}
