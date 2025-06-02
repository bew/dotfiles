{ self, kitsys }:

{
  meta.name = "Mini test kit";
  baseModules = [ ./base.nix ];
  eval = kitsys.defineEval {
    inherit self;
    class = "test-kit";
  };
}
