{ pkgsChannels, mybuilders, ... }:

let
  inherit (pkgsChannels) stable;
in {
  home.packages = [
    (mybuilders.linkBins "android-tools-bins" [
      "${stable.android-tools}/bin/adb"
      "${stable.android-tools}/bin/fastboot"
    ])
  ];
}
