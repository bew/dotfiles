{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.flakeInputs;

  # note: entries for linkFarm must be a list of { name = "foo"; path = "/path"; }
  inputsFarm = pkgs.linkFarm "flake-inputs" (mapAttrsToList (name: drv: {inherit name; path = drv;}) cfg.inputs);
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
        When enabled, store symlinks to all inputs in `flakeInputs.toHomeDirectory` directory.
      '';
    };
    flakeInputs.linkToHome.directory = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Directory where the input links will be stored, relative to home";
    };
  };

  config = mkIf cfg.linkToHome.enable {
    home.file.${cfg.linkToHome.directory}.source = inputsFarm;
  };
}
