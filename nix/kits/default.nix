{ lib, flakeInputs }:

let
  kitsys = import ../kit-system { inherit lib; };
  toolkits = import ./toolkits.nix { inherit kitsys flakeInputs; };
in {
  lib = {
    kitsys = kitsys;
    inherit (toolkits.lib) newToolkit;
  };
  inherit (toolkits) toolkits;
}
