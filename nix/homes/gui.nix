{ config, pkgsChannels, ... }:

let
  inherit (pkgsChannels) stable bleedingedge myPkgs;
in {
  imports = [
    ./gui-fix-xdg-data-dirs.nix
    ./gui-force-system-locales.nix
    ./gui-firefox-native-extensions.nix
    ./gui-espanso-text-expander.nix
  ];

  # Text expansion!
  my.services.espanso = {
    enable = true;
    package = stable.espanso;
    configDir = config.dyndots.mkLink ../../gui/espanso;
  };

  # Check needed native pkg version at:
  # https://github.com/tridactyl/tridactyl/blob/master/native/current_native_version
  # URL found in: https://github.com/tridactyl/native_messenger/blob/62f19dba573b92/installers/install.sh#L53
  my.firefox-native-extensions.tridactyl-native = stable.tridactyl-native;

  my.firefox-native-extensions.uget-integrator = stable.uget-integrator;

  home.packages = [
    stable.uget

    myPkgs.mpv-bew # mpv with scripts
    (myPkgs.mpv-helpers.override { mpv = myPkgs.mpv-bew; }) # @mpv helpers
    # note: need to pass mpv-bew in so that my mpv with config is used when starting
    #   channel-controlled mpv using `@mpv daemon-start foo`

    # desktop/wm related (TODO? nixify config)
    stable.polybar
    stable.dunst
    # FIXME: herbstluftwm is missing here (can't get it to compile last version)

    # X tools
    stable.copyq # powerful clipboard manager
    stable.xclip
    stable.xdotool

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
