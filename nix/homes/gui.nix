{ config, pkgsChannels, ... }:

let
  inherit (pkgsChannels) stable bleedingedge myPkgs;
in {
  imports = [
    ./gui-fix-xdg-data-dirs.nix
    ./gui-force-system-locales.nix
  ];

  xdg.configFile."espanso".source = config.dyndots.mkLink ../../gui/espanso;

  home.packages = [
    stable.dupeguru # Nice cross-platform duplicate finder
  ];
}
