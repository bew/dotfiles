{ lib, config, pkgs, ... }:

let
  ty = lib.types;
  cfg = config.editable;

  directSymlinker = pkgs.callPackage ../mylib/editable-symlinker.nix {};

  directSymlinkerConfigType = ty.submodule {
    options = {
      nixStorePath = lib.mkOption {
        type = ty.pathInStore;
      };
      realPath = lib.mkOption {
        type = ty.singleLineStr;
      };
    };
  };
in {
  options = {
    editable.isSupported = lib.mkOption {
      description = "Whether the config supports editable mode";
      type = ty.bool;
      default = false;
    };

    editable.enable = lib.mkOption {
      description = ''
        Request the config to be editable, FAIL if not supported.
        Use `editable.try_enable` option to silently do nothing if not supported.
      '';
      type = ty.bool;
      default = false;
    };

    editable.try_enable = lib.mkOption {
      description = ''
        Try to make the config to be editable, does nothing if not supported.
      '';
      type = ty.bool;
      default = false;
    };

    editable.config = lib.mkOption {
      description = "The configuration passed to editable-symlinker helper";
      type = directSymlinkerConfigType;
    };

    editable.isEffectivelyEnabled = lib.mkOption {
      description = ''
        Whether editable config is effectively enabled,
        combining checks for isSupported, try_enable & enable.
      '';
      readOnly = true;
      type = ty.bool;
      default = (
        lib.throwIf (cfg.enable && !cfg.isSupported) "editable.enable is true but editable.isSupported is false"
        (cfg.isSupported && (cfg.try_enable || cfg.enable))
      );
    };
  };

  config = {
    lib.mkLink = lib.mkIf cfg.isEffectivelyEnabled (
      directSymlinker cfg.config
    );
  };
}
