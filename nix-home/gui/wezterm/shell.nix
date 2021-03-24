let

  pkgs = import <nixpkgs> {};
  # pkgs-unstable = import (builtins.fetchGit {
  #   # Descriptive name to make the store path easier to identify
  #   name = "nixos-unstable-2020-11-13";
  #   url = "https://github.com/nixos/nixpkgs-channels";
  #   # Commit hash for nixos-unstable at this date
  #   # `git ls-remote https://github.com/nixos/nixpkgs-channels nixos-unstable`
  #   ref = "refs/heads/nixos-unstable";
  #   rev = "84d74ae9c9cbed73274b8e4e00be14688ffc93fe";
  # }) {
  #   overlays = [
  #     (self: super: {
  #       cargo = super.cargo.override {
  #         rustc = self.rustPackages_1_47.rustc;
  #       };
  #     })
  #   ];
  # };

in pkgs.mkShell {
  buildInputs = import ./deps.nix { inherit pkgs; } ++ [
    # We need rustc v1.47, but NixOS is at v1.45
    #pkgs-unstable.cargo
    pkgs.cargo
    # pkgs-unstable.rustc 
    pkgs.pkg-config
  ];
}
