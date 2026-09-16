{ lib, config, pkgs, ... }:

let
  ty = lib.types;
  cfg = config.editable;

  # Shared resolver: turns Roots + global mode into a `mkLink` function.
  resolver = pkgs.callPackage ./roots-resolver.nix { };

  # Root option shape, shared by every entry in `editable.roots`.
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
        type = ty.nullOr (ty.enum [ "editable" "not-editable" ]);
        default = null;
        description = "Per-Root mode; null inherits `editable.isEffectivelyEnabled`";
      };
    };
  };

  # Map the kit's boolean editability onto the resolver's enum mode.
  globalMode = if cfg.isEffectivelyEnabled then "editable" else "not-editable";
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

    editable.roots = lib.mkOption {
      description = ''
        Set of named Roots, each pairing a store path with a live path.
        `lib.mkLink` selects the longest matching Root (by nixStorePath prefix).
      '';
      type = ty.attrsOf rootType;
      default = {};
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
    # Assigned unconditionally: the resolver handles the store-link fallback.
    # A non-null per-Root `mode` still wins even when not effectively enabled.
    lib.mkLink = resolver { roots = cfg.roots; inherit globalMode; };
  };
}
