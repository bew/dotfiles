{ ... }:

{
  meta.name = "Zsh tool kit";

  _evalConfig = {
    class = "tool.zsh";
    baseModules = [
      ../kit-modules/toolkit-base.kit-module.nix
      ./base.nix
    ];
  };
}
