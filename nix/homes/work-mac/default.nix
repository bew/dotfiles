{ pkgsets, kitConfigs, ... }:

let
  inherit (pkgsets) stable mypkgs;
in {
  imports = [
    ../../presets/home/common.nix

    ../../presets/home/cli-core.nix

    ../../presets/home/nix-tools.nix

    ../../presets/home/cli-neovim.nix
  ];
}
