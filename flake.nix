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

    nixpkgsStable.url = "github:nixos/nixpkgs/nixos-22.05";
    nixpkgsUnstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flakeTemplates.url = "github:nixos/templates";

    homeManager.url = "github:nix-community/home-manager/release-22.05";
    homeManager.inputs.nixpkgs.follows = "nixpkgsStable";
  };

  outputs = { self, ... }@inputs: let
    # I only care about ONE system for now...
    system = "x86_64-linux";
  in {
    homeConfig = let
      username = "lesell_b";
    in import "${inputs.homeManager}/modules" {
      pkgs = inputs.nixpkgsStable.legacyPackages.${system};
      configuration = import ./nix/homes/main.nix { inherit inputs system username; };
    };

    # TODO(idea): expose packages (& apps?) of my tools pre-configured,
    # like tmux-bew (easiest), fzf-bew (easy?), nvim-bew (hard), zsh-bew (hard), ...
    # and finally cli-bew (with all previous packages)

    # --- Stuff I want to be able to do with binaries & packages:
    # In my packages:
    # - a `zsh-bew` pkg with a `zsh` binary, configured with my config (using fzf-bew)
    # - a `fzf-bew` pkg with a `fzf` binary, configured with my config
    # - ...
    # In my CLI env:
    # - a `fzf` bin, for normal zsh without config
    # - a `fzf-bew` bin, for zsh with my config (only?)
    # - a way to override my `zsh-bew` drv (with my config) to use `fzf-bew` instead of `fzf`
    #
    # IDEA: Instead of `fzf-bew` having a `fzf` bin, make it a `fzf-bew` bin,
    # and provide a nested drv (`asFzfBin`? or `asUsualBin`?) with normal `fzf` bin.
    # (for re-usability in other drvs, e.g for: `zsh-bew`)
    packages.${system} = let
      selfPkgs = self.packages.${system};
      stablePkgs = inputs.nixpkgsStable.legacyPackages.${system};
      mybuilders = stablePkgs.callPackage ./nix/homes/mylib/mybuilders.nix {};
    in {
      zsh-bew = stablePkgs.callPackage ./zsh/pkg-zsh-bew.nix {
        fzf = selfPkgs.fzf-bew;
      };

      fzf-bew = stablePkgs.callPackage ./nix/pkgs/fzf-with-bew-cfg.nix {};

      #tmux-bew = ...
    };
    apps.${system} = let
      selfPkgs = self.packages.${system};
    in {
      zsh-bew = { type = "app"; program = "${selfPkgs.zsh-bew}/bin/zsh"; };
      fzf-bew = { type = "app"; program = "${selfPkgs.fzf-bew}/bin/fzf"; };
    };
  };
}
