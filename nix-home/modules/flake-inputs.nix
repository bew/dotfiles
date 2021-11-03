{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.flakeInputs;

  inputsToRemove = if !cfg.linkToHome.includeSelf then ["self"] else [];
  consideredInputs = builtins.removeAttrs cfg.inputs inputsToRemove;

  # note: entries for linkFarm must be a list of { name = "foo"; path = "/path"; }
  inputsFarm = pkgs.linkFarm "flake-inputs"
    (mapAttrsToList (name: drv: {inherit name; path = drv;}) consideredInputs);
in {
  options = {
    flakeInputs.inputs = mkOption {
      type = types.attrs;
      default = {};
      description = "The inputs";
    };
    flakeInputs.linkToHome.enable = mkOption {
      type = types.bool;
      default = cfg.linkToHome.directory != null;
      description = ''
        When enabled, store symlinks to all inputs in `flakeInputs.linkToHome.directory` folder.
      '';
    };
    flakeInputs.linkToHome.directory = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Directory where the input links will be stored, relative to home";
    };
    flakeInputs.linkToHome.includeSelf = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to include 'self' in the inputs.
        Disabled by default to avoid un-necessary config rebuild caused by 'any'
        change anywhere in the flake dir.
      '';
    };
  };

  config = mkIf cfg.linkToHome.enable {
    home.file.${cfg.linkToHome.directory}.source = inputsFarm;
  };
}
