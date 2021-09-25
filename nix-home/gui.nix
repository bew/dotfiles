{ config, ... }:

let
  inherit (config.pkgsChannels) stable bleedingedge;
in {
  home.packages = [
    # desktop/wm related (TODO? nixify config)
    stable.polybar
    stable.dunst
    # FIXME: herbstluftwm is missing here (can't get it to compile last version)
    stable.stalonetray # TODO: use it!

    # screen/video capture
    stable.kazam
    stable.screenkey
    stable.slop
  ];
}
