{ config, lib, ... }:

# home-manager specific wiring for dyndots.checkerScript.
# Runs the checker script early in the activation DAG, before any filesystem
# changes, so activation aborts cleanly if an editable link target is missing.
#
# Must be imported alongside nixosModules.dyndots.
{
  config = lib.mkIf (config.dyndots.checkerScript != null) {
    home.activation.checkDyndotsPaths =
      lib.hm.dag.entryBefore ["writeBoundary"] ''
        ${config.dyndots.checkerScript}
      '';
  };
}
