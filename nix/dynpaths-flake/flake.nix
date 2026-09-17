{
  description = "dynpaths — Dynamic paths system for Nix modules";

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
      # Generic module for Nix module system, for use in NixOS/HomeManager/other module systems.
      # Includes: dynpaths options (config) + mkLink (helper fn) + checkerScript (reference).
      modules.generic.dynpaths = import ./dynpaths.nix;

      # home-manager specific module: wires `dynpaths.checkerScript` into
      # `home.activation`, must be imported alongside `modules.generic.dynpaths`.
      modules.homeManager.dynpathsChecker = import ./dynpaths-checker-for-hm.nix;

      # Toolkit module adding dynpaths.* options and lib.mkLink to a toolkit config.
      # Not a NixOS module — intended for use with kit-system eval (or similar).
      modules.kitsys.dynpaths = import ./dynpaths.toolkit-module.nix;

      checks = eachSystem (system:
        let inherit (forSys system) pkgs lib;
        in import ./checks.nix { inherit pkgs lib; dynpaths-flake = self; }
      );
    };
}
