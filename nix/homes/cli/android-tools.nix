{ pkgsChannels, mybuilders, ... }:

let
  inherit (pkgsChannels) stable;
in {
  home.packages = [
    (let androidPkgs = stable.androidenv.androidPkgs_9_0;
    in mybuilders.linkBins "android-tools-bins" [
      "${androidPkgs.platform-tools}/bin/adb"
      "${androidPkgs.platform-tools}/bin/fastboot"
    ])
  ];
}
