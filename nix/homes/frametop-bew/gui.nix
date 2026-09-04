{ config, pkgsets, ... }:

let
  inherit (pkgsets) stable bleedingedge mypkgs;
in {
  imports = [
    ./gui-fix-xdg-data-dirs.nix
    ./gui-force-system-locales.nix
  ];

  xdg.configFile."espanso".source = config.dyndots.mkLink ../../gui-apps/espanso;
  dyndots.checkedPaths = [ config.xdg.configFile."espanso".source ];

  home.packages = [
    stable.dupeguru # Nice cross-platform duplicate finder
  ];
}
