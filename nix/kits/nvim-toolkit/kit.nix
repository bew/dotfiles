{ self, kitsys }:

{
  meta.name = "Nvim tool kit";
  baseModules = [
    ../kit-modules/toolkit-base.kit-module.nix
    ./base.nix
  ];
  eval = kitsys.defineEval {
    inherit self;
    class = "tool.nvim";

    # `lib` option is already defined in tool base module
    declareLibOption = false;
  };
}
