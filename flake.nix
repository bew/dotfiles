# Docs on flakes:
# - https://nixos.wiki/wiki/Flakes
# - https://www.tweag.io/blog/2020-05-25-flakes/
# - https://www.tweag.io/blog/2020-07-31-nixos-flakes/
#
# Example configs:
# - https://github.com/mjlbach/nix-dotfiles/blob/master/nixpkgs/flake.nix
# - https://discourse.nixos.org/t/example-use-nix-flakes-with-home-manager-on-non-nixos-systems/10185

# TODO: a (sensible) minimal flake that can build a home config package for
# normal (copy-files-to-store) & dev use (link-to-dot-files).

{
  description = "Nix flake packaging bew's dotfiles";

  # NOTE: inputs url can be written using the flake reference syntax,
  # documented at https://nixos.org/manual/nix/unstable/command-ref/new-cli/nix3-flake.html#flake-references

  # We use specific branches to get most/all packages from the official cache.
  inputs = {
    # This is the backbone package set, used for tools that should not change too much like tmux
    # (if I have active tmux sessions, I might not want to restart the server if new version is not
    # compatible).
    # Update this channel only if you're not using backbone packages at the moment, or you know
    # they're safe to upgrade.
    nixpkgsBackbone.url = "github:nixos/nixpkgs/nixos-22.05";

    nixpkgsStable.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgsUnstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flakeTemplates.url = "github:nixos/templates";

    homeManager.url = "github:nix-community/home-manager/release-22.05";
    homeManager.inputs.nixpkgs.follows = "nixpkgsStable";

    binHtmlq.url = "github:mgdm/htmlq";
    binHtmlq.inputs.nixpkgs.follows = "nixpkgsStable";
  };

  # TO-EXPERIMENT: flake-parts (https://github.com/hercules-ci/flake-parts) to
  # define my toplevel flake in multiples files, like:
  # * ./nix/homes.flake-module.nix
  # * ./nix/exposed-pkgs.flake-module.nix
  outputs = { self, ... }@inputs: let
    # I only care about ONE system for now...
    system = "x86_64-linux";
  in {
    homeConfig = let
      username = "bew";
    in import "${inputs.homeManager}/modules" {
      pkgs = inputs.nixpkgsStable.legacyPackages.${system};
      configuration = import ./nix/homes/main.nix { inherit inputs system username; };
    };

    # TODO(idea): expose packages (& apps?) of my tools pre-configured,
    # like tmux-bew (easiest), fzf-bew (easy?), nvim-bew (hard), zsh-bew (hard), ...
    # and finally cli-bew (with all previous packages)

    # --- Stuff I want to be able to do with binaries & packages:
    # In my packages:
    # - a `zsh-bew` full pkg with the full `zsh` pkg + `zsh` binary wrapped to use my config (using fzf-bew)
    # - a `fzf-bew` full pkg with the full `fzf` pkg + `fzf` binary wrapped to use my config
    # - a `zsh-bew-bin` pkg with only `${zsh-bew}/bin/zsh`
    # - a `fzf-bew-bin` pkg with only `${fzf-bew}/bin/fzf`
    # - ...
    # => Installing `zsh-bew` or `fzf-bew` should also make `man zsh` & `man fzf` available!
    #    (`man` will auto discover man pages based on binary in `$PATH`, see `man 5 manpath`!)
    #
    # In my CLI env:
    # - a `zsh` bin, with my config (may be editable?)
    # - a `zsh-special-config` bin, for a zsh with a specialized config (bin only)
    # - a `fzf` bin, for fzf with my config
    packages.${system} = let
      selfPkgs = self.packages.${system};
      stablePkgs = inputs.nixpkgsStable.legacyPackages.${system};
      mybuilders = stablePkgs.callPackage ./nix/homes/mylib/mybuilders.nix {};
    in {
      mpv-bew = stablePkgs.callPackage ./nix/pkgs/mpv {};
      mpv-helpers = stablePkgs.callPackage ./nix/pkgs/mpv-helpers {};

      zsh-bew-zdotdir = stablePkgs.callPackage ./zsh/pkg-zsh-bew-zdotdir.nix {
        fzf = selfPkgs.fzf-bew;
      };
      zsh-bew = let
        # zsh pkg wrapper, using my zsh-bew-zdotdir as configuration
        pkg = { buildEnv, makeWrapper, zsh, zdotdir }:
          mybuilders.replaceBinsInPkg {
            name = "zsh-bew";
            copyFromPkg = zsh;
            nativeBuildInputs = [ makeWrapper ];
            postBuild = /* sh */ ''
              makeWrapper ${zsh}/bin/zsh $out/bin/zsh --set ZDOTDIR ${selfPkgs.zsh-bew-zdotdir}
            '';
          };
      in stablePkgs.callPackage pkg { zdotdir = selfPkgs.zsh-bew-zdotdir; };
      zsh-bew-bin = mybuilders.linkSingleBin "${selfPkgs.zsh-bew}/bin/zsh";

      fzf-bew = stablePkgs.callPackage ./nix/pkgs/fzf-with-bew-cfg.nix {
        replaceBinsInPkg = mybuilders.replaceBinsInPkg;
      };
      fzf-bew-bin = mybuilders.linkSingleBin "${selfPkgs.fzf-bew}/bin/fzf";

      #tmux-bew = ...
    };
    apps.${system} = let
      selfPkgs = self.packages.${system};
      selfApps = self.apps.${system};
    in {
      default = selfApps.zsh-bew; # FIXME: should be an env with all 'core' cli tools
      zsh-bew = { type = "app"; program = "${selfPkgs.zsh-bew}/bin/zsh"; };
      fzf-bew = { type = "app"; program = "${selfPkgs.fzf-bew}/bin/fzf"; };
    };
  };
}
