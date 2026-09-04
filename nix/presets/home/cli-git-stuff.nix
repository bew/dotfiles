{ pkgsets, ... }:

let
  inherit (pkgsets) stable;
in {
  home.packages = [
    (stable.callPackage ../../../git/package-bew-env.nix {})
  ];
}
