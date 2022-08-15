{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.nixRegistry;
in {
  options = {
    nixRegistry.indirectFlakes = mkOption {
      # NOTE: types.uniq ensures that multiple definitions of the same flake will not try to merge
      # them, it will raise an error instead.
      type = types.attrsOf (types.uniq types.attrs);
      default = {};
      description = ''
        Attrset associating a flake name to flake reference (as an attrset not as a string).
      '';
      example = {
        thepkgs = { type = "path"; path = nixpkgs.outPath; };
      };
    };
    nixRegistry.rawFlakes = mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = "Additional raw flakes full definitions for the registry";
      example = [
        {
          from = { id = "thepkgs"; type = "indirect"; };
          to = { type = "path"; path = nixpkgs.outPath; };
          # flake ref: "path:${nixpkgs.outPath}"
        }
        {
          from = { id = "latest-pkgs"; type = "indirect"; };
          to = {
            # flake ref: "github:nixos/nixpkgs"
            type = "github";
            owner = "nixos";
            repo = "nixpkgs";
          };
        }
      ];
    };
  };

  config = mkIf (cfg.indirectFlakes != {} || cfg.rawFlakes != {}) {
    # Inspired from https://gitlab.univ-rouen.fr/sreycoyrehourcq/dotfiles/-/blob/2ef3b82d6a/flake.nix#L127
    xdg.configFile."nix/registry.json".text = builtins.toJSON {
      version = 2;
      flakes = (mapAttrsToList (flakeName: flakeValue: {
        from = {id = flakeName; type = "indirect"; };
        to = flakeValue;
      }) cfg.indirectFlakes) ++ cfg.rawFlakes;
    };
  };
}
