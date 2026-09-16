{ config, lib, pkgs, ... }:

let
  cfg = config.dynpaths;

  # Shared resolver: turns Roots + global mode into a `mkLink` function.
  resolver = pkgs.callPackage ./roots-resolver.nix { };

  # Root option shape, shared by every entry in `dynpaths.roots`.
  rootType = lib.types.submodule {
    options = {
      nixStorePath = lib.mkOption {
        type = lib.types.pathInStore;
        description = "Store-side base of the Root (may be a nested subdir of a store path)";
        example = "./nvim";
      };
      realPath = lib.mkOption {
        type = lib.types.path;
        description = ''
          Absolute live on-disk base of the Root, where the source is checked out and edited.
          NOTE: must be a live path outside the store. A relative path literal (e.g. ./dot)
          is coerced by Nix into a store path and silently breaks the live-path contract;
          pass an absolute string or an absolute path value.
        '';
        example = ''"/home/bew/.dot"'';
      };
      mode = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum [ "editable" "not-editable" ]);
        default = null;
        description = "Per-Root mode; null inherits the global `dynpaths.mode`";
      };
    };
  };

  # A Root's mode wins when set, otherwise the global mode applies.
  effectiveMode = root: if root.mode != null then root.mode else cfg.mode;

  # Editable links are only checked when at least one Root resolves to editable.
  anyEditableRoot = lib.any (root: effectiveMode root == "editable") (lib.attrValues cfg.roots);
in
{
  options = with lib; {
    dynpaths.mode = mkOption {
      type = types.enum [ "editable" "not-editable" ];
      default = "not-editable";
    };

    dynpaths.roots = mkOption {
      type = types.attrsOf rootType;
      default = { };
      description = ''
        Set of named Roots, each pairing a store path with a live path.
        `dynpaths.mkLink` selects the longest matching Root (by nixStorePath prefix).
      '';
    };

    dynpaths.mkLink = mkOption {
      description = "Entrypoint helper function to be used to make dynpaths links (may be editable)";
    };

    dynpaths.checkedPaths = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        List of paths to verify at activation time (before any filesystem changes).
        Each entry with a `dynpathRedirectTarget` passthru attribute will have its real
        path verified to exist. Entries without that attribute are silently skipped.

        Recommended: register the final option value rather than the mkLink result
        directly, so any later override of that option is also checked:
          {
            xdg.configFile."foo".source = config.dynpaths.mkLink ./some/path;
            dynpaths.checkedPaths = [ config.xdg.configFile."foo".source ];
          }
      '';
    };

    dynpaths.checkerScript = mkOption {
      type = types.nullOr types.package;
      readOnly = true;
      description = ''
        A script derivation that checks all dynpaths.checkedPaths exist on the real filesystem.
        Null when no Root resolves to editable (nothing to check).
        Intended to be wired into an activation script by a higher-level module
        (e.g. dynpaths-checker-for-hm.nix).
      '';
    };
  };

  config = {
    # Warn early when editable mode is requested but no Root can ever match.
    dynpaths.mkLink =
      lib.warnIf (cfg.mode == "editable" && cfg.roots == { })
        "dynpaths: mode is 'editable' but no roots are declared; all links will fall back to store links"
        (resolver { roots = cfg.roots; globalMode = cfg.mode; });

    dynpaths.checkerScript = (
      if !anyEditableRoot then
        null
      else
        let
          # Generate a check for each path registered to be checked
          checks = lib.concatMapStringsSep "\n" (
            pathDrv:
            lib.optionalString (pathDrv ? dynpathRedirectTarget) /* bash */ ''
              _dynpaths_target=${lib.escapeShellArg pathDrv.dynpathRedirectTarget}
              if [[ ! -e "$_dynpaths_target" ]]; then
                >&2 echo "dynpaths: editable link target does not exist: '$_dynpaths_target' (matched root: ${pathDrv.dynpathMatchedRoot.name})"
                _dynpaths_failed=1
              fi
            ''
          ) cfg.checkedPaths;
          checkedPathsCount = builtins.length cfg.checkedPaths;
        in
        pkgs.writeShellScript "dynpaths-check-paths" ''
          _dynpaths_failed=0
          ${checks}
          if [[ $_dynpaths_failed -eq 0 ]]; then
            >&2 echo "dynpaths: All ${toString checkedPathsCount} paths exist, config ok."
          else
            # warning were printed before during each path check
            exit 1
          fi
        ''
    );
  };
}
