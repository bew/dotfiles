{ flakeInputs }:

let
  kitsys = flakeInputs.kit-system.lib.kitsys;
  toolkits = import ./toolkits.nix { inherit kitsys flakeInputs; };
in {
  lib = {
    inherit kitsys;
    inherit (toolkits.lib) newToolkit;
  };
  inherit (toolkits) toolkits;
}
