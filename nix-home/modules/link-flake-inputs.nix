{ config, lib, pkgs, flakeInputs, ... }:

with lib;

let
  cfg = config.linkFlakeInputs;

  inputsToRemove = if !cfg.includeSelf then ["self"] else [];
  consideredInputs = builtins.removeAttrs flakeInputs inputsToRemove;

  # note: entries for linkFarm must be a list of { name = "foo"; path = "/path"; }
  inputsFarm = pkgs.linkFarm "flake-inputs"
    (mapAttrsToList (name: drv: {inherit name; path = drv;}) consideredInputs);
in {
  options = {
    linkFlakeInputs.enable = mkOption {
      type = types.bool;
      default = cfg.directory != null;
      description = ''
        When enabled, store symlinks to all inputs in `linkFlakeInputs.directory` folder.
      '';
    };
    linkFlakeInputs.directory = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Directory where the input links will be stored, relative to home";
    };
    linkFlakeInputs.includeSelf = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to include 'self' in the inputs.
        Disabled by default to avoid un-necessary config rebuild caused by 'any'
        change anywhere in the flake dir.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.file.${cfg.directory}.source = inputsFarm;
  };
}
