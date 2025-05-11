{ self, kitsys }:

{
  meta.name = "Mini example kit";
  baseModules = [ ./base.nix ];
  eval = kitsys.defineEval {
    inherit self;
    class = "example-kit";
  };
}
