{
  description = "dyndots — editable dotfiles symlink system for Nix/home-manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = { self, nixpkgs, systems }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
      forSys = system: {
        pkgs = nixpkgs.legacyPackages.${system};
        lib = nixpkgs.lib;
      };
    in {
      # Generic NixOS/nix module: dyndots options + mkLink.
      # No home-manager dependency.
      modules.generic.dyndots = import ./dyndots.nix;

      # Kit module adding editable.* options and lib.mkLink to a kit config.
      # Not a NixOS module — intended for use with kit-system eval (or similar).
      modules.kitsys.editable = import ./editable.kit-module.nix;
    };
}
