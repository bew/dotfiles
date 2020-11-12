{ pkgs }:

let p = pkgs; in [
  p.cmake
  p.curl
  p.dbus
  p.egl-wayland
  p.expat
  p.fontconfig
  p.gettext
  p.git
  p.gnumake
  p.xorg.libxcb
  p.libxkbcommon
  p.mesa
  p.openssl
  # p5-ExtUtils-MakeMaker (WTF is this??)
  p.perl
  p.pkgconf
  p.python3
  # rust (implicit)
  p.wayland
  p.xorg.xcbutilkeysyms
  p.xorg.xcbutilwm
  # z
  p.zip
  p.libGL # added, but should be required.. right?

  # added while trying to build manually using nix-shell
  p.xorg.libX11
]
