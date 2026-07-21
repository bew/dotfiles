{ config, lib, pkgs, ... }:

let
  cfg = config.dyndots;
in
{
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

    dyndots.checkedPaths = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = ''
        List of paths to verify at activation time (before any filesystem changes).
        Each entry with a `dyndotsRedirectTarget` passthru attribute will have its real
        path verified to exist. Entries without that attribute are silently skipped.

        Recommended: register the final option value rather than the mkLink result
        directly, so any later override of that option is also checked:
          {
            xdg.configFile."foo".source = config.dyndots.mkLink ./some/path;
            dyndots.checkedPaths = [ config.xdg.configFile."foo".source ];
          }
      '';
    };

    dyndots.checkerScript = mkOption {
      type = types.nullOr types.package;
      readOnly = true;
      description = ''
        A script derivation that checks all dyndots.checkedPaths exist on the real filesystem.
        Null when mode is not-editable (nothing to check).
        Intended to be wired into an activation script by a higher-level module
        (e.g. dyndots-hm.nix).
      '';
    };
  };

  config = let
    mkStoreLink = givenPath: givenPath; # Caller takes the path as-is (and copy it to store on use)
    mkEditableDirectLink = (pkgs.callPackage ./editable-symlinker.nix { }) {
      nixStorePath = cfg.dotfilesNixPath;
      realPath = cfg.dotfilesRealPath;
    };
  in
  {
    dyndots.mkLink = (if cfg.mode == "editable" then mkEditableDirectLink else mkStoreLink);

    dyndots.checkerScript = (
      if cfg.mode != "editable" then
        null
      else
        let
          # Generate a check for each path registered to be checked
          checks = lib.concatMapStringsSep "\n" (
            pathDrv:
            lib.optionalString (pathDrv ? dyndotsRedirectTarget) /* bash */ ''
              _dyndots_target=${lib.escapeShellArg pathDrv.dyndotsRedirectTarget}
              if [[ ! -e "$_dyndots_target" ]]; then
                >&2 echo "dyndots: editable link target does not exist: '$_dyndots_target'"
                _dyndots_failed=1
              fi
            ''
          ) cfg.checkedPaths;
          checkedPathsCount = builtins.length cfg.checkedPaths;
        in
        pkgs.writeShellScript "dyndots-check-paths" ''
          _dyndots_failed=0
          ${checks}
          if [[ $_dyndots_failed -eq 0 ]]; then
            >&2 echo "dyndots: All ${toString checkedPathsCount} paths exist, config ok."
          else
            # warning were printed before during each path check
            exit 1
          fi
        ''
    );
  };
}
