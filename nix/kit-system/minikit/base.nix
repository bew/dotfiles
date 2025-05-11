{ lib, ... }:

{
  options = let ty = lib.types; in {
    foo = lib.mkOption {
      type = lib.types.singleLineStr;
    };
  };
}
