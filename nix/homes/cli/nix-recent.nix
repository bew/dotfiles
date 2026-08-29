{ config, pkgsChannels, ... }:

let
  inherit (pkgsChannels) stable bleedingedge;
in {
  # Use latest Nix!
  nix.package = bleedingedge.nixVersions.latest;
  # Also make it available in $PATH
  home.packages = [ config.nix.package ];
}
