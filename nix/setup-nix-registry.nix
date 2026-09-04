{ flakeInputs }:

let
  lib = flakeInputs.nixpkgsStable.lib;
in
{
  nix.registry = {
    # -> flake ref: "path:${nixpkgs.outPath}"
    pkgs.flake = flakeInputs.nixpkgsStable;
    # -> flake ref: "github:nixos/nixpkgs/nixpkgs-unstable"
    unstable.to = {
      type = "github";
      owner = "nixos";
      repo = "nixpkgs";
      ref = "nixpkgs-unstable";
    };
    # -> flake ref: "path:${officialTemplates.outPath}"
    official-templates.flake = flakeInputs.officialTemplates;
    # -> flake ref: "path:${myTemplates.outPath}"
    mytpl.flake = flakeInputs.myTemplates;
  };
}
