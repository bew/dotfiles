{ config, pkgsChannels, ... }:

let
  inherit (pkgsChannels) stable bleedingedge;
in {
  home.packages = [
    # desktop/wm related (TODO? nixify config)
    stable.polybar
    stable.dunst
    # FIXME: herbstluftwm is missing here (can't get it to compile last version)
    stable.copyq # powerful clipboard manager

    # FIXME: `arandr` disabled because it can't load menu icons :/
    #        and installing hicolor-icon-theme doesn't solve it..
    # stable.arandr
    stable.autorandr

    # screen/video capture
    stable.simplescreenrecorder # simple (to use) yet powerful Screen Recorder
    stable.screenkey
    stable.slop
    # stable.peek ? (for gifs iirc)
  ];
}
