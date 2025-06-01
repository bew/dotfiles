{ lib, ... }:

{
  options = let ty = lib.types; in {
    val = lib.mkOption {
      description = "Option to test nesting config with overriden value";
      type = ty.anything;
    };
  };
}
