{ nixpkgs ? import <nixpkgs> {} }:

let
  # NOTE: we use an appimage binary directly, it currently works on my Arch system,
  # but it may break on a pure NixOS system.
  wezterm-bin = let
    version = "20200909-002054-4c9af461";
    dl_pkg = nixpkgs.fetchurl {
      url =
        "https://github.com/wez/wezterm/releases/download/${version}/WezTerm-${version}-Ubuntu16.04.AppImage";
      sha256 = "080mh64620swxcjs76lriay2dpcvb94mha83gbxprnb0sf4rgp0k";
      executable = true;
    };
  in nixpkgs.runCommand "wezterm-bin-${version}" {} ''
    mkdir -p $out/bin
    ln -s ${dl_pkg} $out/bin/wezterm
  '';

in wezterm-bin

# TODO: FIXME: what to do with this file? where to use it?
