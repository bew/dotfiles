{ pkgsChannels, pkgs, ... }:

let
  inherit (pkgsChannels) stable bleedingedge;
in {
  home.packages = [
    (stable.callPackage ../../../git/package-bew-env.nix {})
  ];
}
