{ pkgsets, kitConfigs, ... }:

let
  inherit (pkgsets) stable mypkgs;
in {
  imports = [
    ../../presets/home/common.nix

    ../../presets/home/cli-core.nix

    ../../presets/home/nix-tools.nix

    ../../presets/home/cli-neovim.nix

    # FIXME: find a way to not have to import those here 🤔
    kitConfigs.zsh-bew.outputs.homeModules.withDefaults
    kitConfigs.tmux-bew.outputs.homeModules.withDefaults
  ];
}
