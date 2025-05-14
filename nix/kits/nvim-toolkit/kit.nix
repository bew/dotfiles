{ self, kitsys }:

{
  meta.name = "Nvim tool kit";
  baseModules = [
    ../../tool-configs-factory/baseModule.nix
    ./base.nix
  ];
  eval = kitsys.defineEval {
    inherit self;
    class = "tool.nvim";

    # `lib` option is already defined in tool base module
    declareLibOption = false;
  };
}
