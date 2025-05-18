{ self, kitsys }:

{
  meta.name = "Tmux tool kit";
  baseModules = [
    ../../tool-configs-factory/baseModule.nix
    ./base.nix
  ];
  eval = kitsys.defineEval {
    inherit self;
    class = "tool.tmux";

    # `lib` option is already defined in tool base module
    declareLibOption = false;
  };
}
