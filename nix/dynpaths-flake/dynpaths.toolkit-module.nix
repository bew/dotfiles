{ lib, config, pkgs, ... }:

let
  ty = lib.types;
  dynpathsCfg = config.dynpaths;
  cfg = config.dynamicConfig;

  # Shared resolver: turns Roots + global mode into a `mkLink` function.
  resolver = pkgs.callPackage ./roots-resolver.nix { };

  # Root option shape, shared by every entry in `dynpaths.roots`.
  rootType = ty.submodule {
    options = {
      nixStorePath = lib.mkOption {
        type = ty.pathInStore;
        description = "Store-side base of the Root (may be a nested subdir of a store path)";
      };
      realPath = lib.mkOption {
        type = ty.path;
        description = ''
          Absolute live on-disk base of the Root, where the source is checked out and edited.
          NOTE: must be a live path outside the store.
        '';
      };
      mode = lib.mkOption {
        type = ty.nullOr (ty.enum [ "dynamic" "static" ]);
        default = null;
        description = "Per-Root mode; null inherits `dynamicConfig.isEffectivelyEnabled`";
      };
    };
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
