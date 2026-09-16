{ config, lib, ... }:

# home-manager specific wiring for dynpaths.checkerScript.
# Runs the checker script early in the activation DAG, before any filesystem
# changes, so activation aborts cleanly if an editable link target is missing.
#
# Must be imported alongside nixosModules.dynpaths.
{
  config = lib.mkIf (config.dynpaths.checkerScript != null) {
    home.activation.checkDynpathsTargets =
      lib.hm.dag.entryBefore ["writeBoundary"] ''
        ${config.dynpaths.checkerScript}
      '';
  };
}
