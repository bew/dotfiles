{ config, pkgsChannels, ... }:

let
  inherit (pkgsChannels) stable bleedingedge myPkgs;
in {
  imports = [
    ./gui-fix-xdg-data-dirs.nix
    ./gui-force-system-locales.nix
    ./gui-espanso-text-expander.nix
  ];

  # Text expansion!
  my.services.espanso = {
    enable = true;
    package = stable.espanso;
    configDir = config.dyndots.mkLink ../../gui/espanso;
  };

  home.packages = [
    # desktop/wm related (TODO? nixify config)
    stable.dunst
    # FIXME: herbstluftwm is missing here (can't get it to compile last version)

    # X tools
    stable.copyq # powerful clipboard manager
    stable.xclip
    stable.xdotool

    stable.arandr

    (stable.redshift.override { withGeolocation = false; })

    # screen/video capture
    stable.simplescreenrecorder # simple (to use) yet powerful Screen Recorder
    stable.screenkey
    stable.slop
    # stable.peek ? (for gifs iirc)
  ];
}
