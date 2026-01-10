{ ... }:

{
  meta.name = "Nvim tool kit";

  _evalConfig = {
    class = "tool.nvim";
    baseModules = [
      # FIXME: how to access `my-nix-commons` here???
      # .. I'd need to access them from the fn args somehow
      #    => Need to find a way to call newKit with extra base modules 🤔
      ../kit-modules/toolkit-base.kit-module.nix
      ./base.nix
    ];
  };
}
