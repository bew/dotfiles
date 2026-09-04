{ config, pkgs, ... }:

{
  _module.args.mypkglib = pkgs.callPackage ../../mypkglib.nix {};

  # Do not build home-manager's manual, it brings a number of useless dependencies and I don't need
  # them often anyway.
  manual.manpages.enable = false;
}
