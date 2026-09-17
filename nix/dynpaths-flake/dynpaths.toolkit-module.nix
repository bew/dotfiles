{ lib, config, pkgs, ... }:

let
  ty = lib.types;
  dynpathsCfg = config.dynpaths;
  cfg = config.dynamicConfig;

  # Shared resolver: turns Roots + global mode into a `mkLink` function.
  resolver = pkgs.callPackage ./roots-resolver.nix { };

  # Per-Root option schema, shared with the generic module.
  rootType = import ./roots-type.nix {
    inherit lib;
    defaultsToInheritFrom = "`dynamicConfig.isEffectivelyEnabled`";
  };

  # Map the toolkit's boolean dynamic support onto the resolver's enum mode.
  globalMode = if cfg.isEffectivelyEnabled then "dynamic" else "static";
in {
  options = {
    dynamicConfig.isSupported = lib.mkOption {
      description = "Whether the toolkit declares support for dynamic config";
      type = ty.bool;
      default = false;
    };

    dynamicConfig.enable = lib.mkOption {
      description = ''
        Request the config to be dynamic, will FAIL the eval if not supported.
        Use `dynamicConfig.tryEnable` option to silently do nothing if not supported.
      '';
      type = ty.bool;
      default = false;
    };

    dynamicConfig.tryEnable = lib.mkOption {
      description = ''
        Try to make the config dynamic, does nothing if not supported.
      '';
      type = ty.bool;
      default = false;
    };

    dynpaths.roots = lib.mkOption {
      description = ''
        Set of named Roots, each pairing a store path with a live path.
        `lib.mkLink` selects the longest matching Root (by nixStorePath prefix).
      '';
      type = ty.attrsOf rootType;
      default = {};
    };

    dynamicConfig.isEffectivelyEnabled = lib.mkOption {
      description = ''
        Whether dynamic mode is effectively enabled,
        combining checks for isSupported, tryEnable & enable.
      '';
      readOnly = true;
      type = ty.bool;
      default = (
        lib.throwIf (cfg.enable && !cfg.isSupported) "dynamicConfig.enable is true but dynamicConfig.isSupported is false"
        (cfg.isSupported && (cfg.tryEnable || cfg.enable))
      );
    };
  };

  config = {
    # Assigned unconditionally: the resolver handles the store-copy fallback.
    # A non-null per-Root `mode` still wins even when not effectively enabled.
    lib.mkLink = resolver { roots = dynpathsCfg.roots; inherit globalMode; };
  };
}
