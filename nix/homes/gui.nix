{ config, pkgsChannels, ... }:

let
  inherit (pkgsChannels) stable bleedingedge;
in {
  imports = [
    ./gui-fix-xdg-data-dirs.nix
    ./gui-force-system-locales.nix
    ./gui-firefox-tridactyl-native-extension.nix
  ];

  # Check needed native pkg version at:
  # https://github.com/tridactyl/tridactyl/blob/master/native/current_native_version
  # URL found in: https://github.com/tridactyl/native_messenger/blob/62f19dba573b92/installers/install.sh#L53
  my.firefox-tridactyl-native.package = pkgsChannels.stable.tridactyl-native;

  home.packages = [
    # desktop/wm related (TODO? nixify config)
    stable.polybar
    stable.dunst
    # FIXME: herbstluftwm is missing here (can't get it to compile last version)

    # X tools
    stable.copyq # powerful clipboard manager
    stable.xclip
    stable.xdotool

    #bleedingedge.ripdrag # drag/drop files from/to terminal :)
    # Not adding right now, individual testing shows using it as target doesn't
    # really work....
    # `ripdrag --target --print-path --and-exit` doesn't react when I drag a
    # file onto the window :/
    #
    # And it adds 800M to the closure size :/
    # => Really want to have a standalone HM profile for gui apps...

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
