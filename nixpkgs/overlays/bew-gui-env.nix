# This file must be in ~/.config/nixpkgs/overlays/
# Ref: https://nixos.org/manual/nixpkgs/stable/#chap-overlays

# FIXME: this is not ideal, because I am tied to the 'global' nixpkgs version.
# I want to use a specific nixpkgs version instead,
# to avoid hard-to-track update breakings.

final: prev:

let
  # nixpkgs-for-hlwm = import (builtins.fetchTarball {
  #   # Descriptive name to make the store path easier to identify
  #   name = "nixpkgs-unstable-2021-02-24";
  #   url = "https://github.com/nixos/nixpkgs/archive/4d0c9f2c27b70eb4d211748b84ee8e5090ec468f.tar.gz";
  #   # Hash obtained using `nix-prefetch-url --unpack <url>`
  #   sha256 = "0bbl271g9icqs9pxy6ddhk9nwgphglnsilw57zagim35jcj3ss4q";
  # }) {};
  #
  # FIXME: DOES NOT COMPILE :/
  # herbstluftwm-recent = nixpkgs-for-hlwm.herbstluftwm.override {asciidoc = prev.asciidoc;};
in {
  # Ref: https://nixos.org/nixpkgs/manual/#sec-declarative-package-management
  bew-gui-env = prev.buildEnv {
    name = "bew-gui-env";
    paths = let p = prev; in [

      # desktop/wm related (TODO? nixify config)
      p.polybar
      # FIXME: herbstluftwm is missing here (can't get it to compile last version)
      p.stalonetray # TODO: use it!

      # screen/video capture
      p.kazam
      p.screenkey
      p.slop
    ];
  };
}
