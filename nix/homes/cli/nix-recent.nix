{ config, pkgsChannels, ... }:

let
  inherit (pkgsChannels) stable bleedingedge;
in {
  # Use recent Nix!
  nix.package = bleedingedge.nix;
  # Also make it available in $PATH
  home.packages = [ config.nix.package ];
}
