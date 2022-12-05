{ config, pkgsChannels, ... }:

let
  inherit (pkgsChannels) stable bleedingedge;

  copyq-latest = stable.copyq.overrideAttrs (oldAttrs: rec {
    version = "6.2.0";
    src = stable.fetchFromGitHub {
      owner = "hluk";
      repo = "CopyQ";
      rev = "v${version}";
      hash = "sha256-0XCqSF1oc2B3FD5OmOxqgt9sqCIrzK0KjkntVFXlRWI=";
    };
  });
in {
  imports = [
    ./gui-fix-xdg-data-dirs.nix
  ];

  home.packages = [
    # desktop/wm related (TODO? nixify config)
    stable.polybar
    stable.dunst
    # FIXME: herbstluftwm is missing here (can't get it to compile last version)

    # X tools
    copyq-latest # powerful clipboard manager
    stable.xclip

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
