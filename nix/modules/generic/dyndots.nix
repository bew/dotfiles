{ config, lib, pkgs, ... }:

let
  cfg = config.dyndots;
in {
  options = with lib; {
    dyndots.mode = mkOption {
      type = types.enum ["editable" "not-editable"];
      default = "not-editable";
    };
    dyndots.dotfilesRealPath = mkOption {
      type = types.nullOr types.path; # something that coerces to an absolute path
      description = "Path to the dotfiles repo, will be used as the base for editable links";
      example = ''"/home/user/path/to/dotfiles"'';
      default = null;
    };

    dyndots.dotfilesNixPath = mkOption {
      type = types.nullOr types.pathInStore;
      description = ''
        Since flake eval is pure, the source is moved to the store and all resolved ./relative paths
        start in the store. This `dotfilesNixPath` will be used to strip the store location and get
        back a real relative path from the flake (dotfiles directory).
      '';
    };

    dyndots.mkLink = mkOption {
      # type = types.functionTo types.package;  # FIXME: can't find a type that works..
      description = "Entrypoint helper function to be used to make dyndots links (may be editable)";
    };
  };

  config = let
    mkStoreLink = givenPath: givenPath; # nothing to do, will be converted by home-manager
    mkEditableDirectLink = (pkgs.callPackage ../../mylib/editable-symlinker.nix {}) {
      nixStorePath = cfg.dotfilesNixPath;
      realPath = cfg.dotfilesRealPath;
    };
  in {
    dyndots.mkLink =
      if cfg.mode == "editable"
      then mkEditableDirectLink
      else mkStoreLink;
  };
}
