{ config, lib, pkgs, ... }:

let
  cfg = config.dynpaths;

  # Shared resolver: turns Roots + global mode into a `mkLink` function.
  resolver = pkgs.callPackage ./roots-resolver.nix { };

  # Per-Root option schema, shared with the toolkit module.
  rootType = import ./roots-type.nix {
    inherit lib;
    defaultsToInheritFrom = "the global `dynpaths.mode`";
  };

  # A Root's mode wins when set, otherwise the global mode applies.
  effectiveMode = root: if root.mode != null then root.mode else cfg.mode;

  # Symlink redirects are only checked when at least one Root resolves to dynamic.
  anyDynamicRoot = lib.any (root: effectiveMode root == "dynamic") (lib.attrValues cfg.roots);
in
{
  options = with lib; {
    dynpaths.mode = mkOption {
      type = types.enum [ "dynamic" "static" ];
      default = "static";
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
      description = "Entrypoint helper function to be used to make dynpaths references (may be dynamic!)";
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
        Null when no Root resolves to dynamic (nothing to check).
        Intended to be wired into an activation script by a higher-level module
        (e.g. dynpaths-checker-for-hm.nix).
      '';
    };
  };

  config = {
    # Warn early when dynamic mode is requested but no Root can ever match.
    dynpaths.mkLink =
      lib.warnIf (cfg.mode == "dynamic" && cfg.roots == { })
        "dynpaths: mode is 'dynamic' but no roots are declared; all links will fall back to store copies"
        (resolver { roots = cfg.roots; globalMode = cfg.mode; });

    dynpaths.checkerScript = (
      if !anyDynamicRoot then
        null
      else
        let
          # Generate a check for each path registered to be checked
          checks = lib.concatMapStringsSep "\n" (
            pathDrv:
            lib.optionalString (pathDrv ? dynpathRedirectTarget) /* bash */ ''
              _dynpaths_target=${lib.escapeShellArg pathDrv.dynpathRedirectTarget}
              if [[ ! -e "$_dynpaths_target" ]]; then
                >&2 echo "dynpaths: symlink redirect target does not exist: '$_dynpaths_target' (matched root: ${pathDrv.dynpathMatchedRoot.name})"
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
