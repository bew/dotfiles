{ lib, defaultsToInheritFrom }:

let
  ty = lib.types;
in

# Per-Root option schema shared by the generic `dynpaths` module and the toolkit
# module. Callers supply the description of what an unset per-Root `mode` inherits.
ty.submodule {
  options = {
    nixStorePath = lib.mkOption {
      type = ty.pathInStore;
      description = "Store-side base of the Root (may be a nested subdir of a store path)";
      example = "./nvim";
    };

    realPath = lib.mkOption {
      type = ty.path;
      description = ''
        Absolute live on-disk base of the Root, where the source is checked out and edited.
        NOTE: must be a live path outside the store. A relative path literal (e.g. ./dot)
        is coerced by Nix into a store path and silently breaks the live-path contract;
        pass an absolute string or an absolute path value.
      '';
      example = ''"/home/bew/.dot"'';
    };

    mode = lib.mkOption {
      type = ty.nullOr (ty.enum [ "dynamic" "static" ]);
      default = null;
      description = "Per-Root mode; defaults to inherit ${defaultsToInheritFrom}";
    };
  };
}
