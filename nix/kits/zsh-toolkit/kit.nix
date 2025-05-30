{ self, kitsys }:

{
  meta.name = "Zsh tool kit";
  baseModules = [
    ../kit-modules/toolkit-base.kit-module.nix
    ./base.nix
  ];
  eval = kitsys.defineEval {
    inherit self;
    class = "tool.zsh";

    # `lib` option is already defined in tool base module
    declareLibOption = false;
  };
}
