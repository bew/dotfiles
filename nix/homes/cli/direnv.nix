{ config, pkgsChannels, lib, mybuilders, flakeInputs, pkgs, myToolConfigs, ... }:

let
  inherit (pkgsChannels) stable bleedingedge myPkgs;
in {
  home.packages = [
    stable.direnv
  ];

  # Add nix-direnv' `use nix`/`use flake` impl to have good caching of the generated nix dev shells
  # (referenced in gcroots to avoid auto-GC and re-fetch when opening projects after few weeks)
  #
  # Ref: https://direnv.net/man/direnv.1.html
  # > You can also define your own extensions inside $XDG_CONFIG_HOME/direnv/direnvrc or $XDG_CONFIG_HOME/direnv/lib/*.sh files.
  xdg.configFile."direnv/lib/nix-direnv.sh".source = "${stable.nix-direnv}/share/nix-direnv/direnvrc";
}
