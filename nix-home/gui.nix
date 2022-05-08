{ config, pkgsChannels, ... }:

let
  inherit (pkgsChannels) stable bleedingedge;
in {
  imports = [
    ./gui-fix-default-icons.nix
  ];

  home.packages = [
    # desktop/wm related (TODO? nixify config)
    stable.polybar
    stable.dunst
    # FIXME: herbstluftwm is missing here (can't get it to compile last version)
    stable.copyq # powerful clipboard manager

    stable.arandr
    stable.autorandr

    (stable.redshift.override { withGeolocation = false; })

    # screen/video capture
    stable.simplescreenrecorder # simple (to use) yet powerful Screen Recorder
    stable.screenkey
    stable.slop
    # stable.peek ? (for gifs iirc)
  ];
}
