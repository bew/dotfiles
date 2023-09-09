{ config, lib, ... }:

let
  cfg = config.dyndots;
in {
  options = with lib; {
    dyndots.mode = mkOption {
      type = types.enum ["editable" "not-editable"];
      default = "not-editable";
    };
    dyndots.dotfilesRepoPath = mkOption {
      type = types.nullOr types.path; # something that coerces to an absolute path
      description = "Path to the dotfiles repo, will be used for the out-of-store link";
      example = ''"/home/user/path/to/dotfiles"'';
      default = null;
    };

    # TODO(?): find a better option name?
    # ideas:
    # - selfInput
    # - selfFlake
    # - selfFlakeLocation
    # - selfStorePath
    # - selfStoreLocation
    # - pathToStrip
    # - pureFlakePathToStrip
    # - pureSelfSourcePath
    # - pureFlakeSourcePath
    # - pureSourcePath
    # - flakeLocation
    # - flakePureLocation
    # - ?
    dyndots.flakeStorePath = mkOption {
      # type = types.pathInStore;  # only available in unstable nixpkgs (not in 23.05)
      # here is a copy/paste from more recent nixpkgs:
      type = let
        pathInStore = mkOptionType {
          name = "pathInStore";
          description = "path in the Nix store";
          descriptionClass = "noun";
          check = x: let
            isStringLike = (x:
              builtins.isString x
              || builtins.isPath x
              || x ? outPath
              || x ? __toString
            );
          in isStringLike x && builtins.match "${builtins.storeDir}/[^.].*" (toString x) != null;
          merge = mergeEqualOption;
        };
      in types.nullOr pathInStore;

      description = ''
        Since flake eval is pure, the source is moved to the store and all resolved ./relative paths
        start in the store. This `flakeStorePath` will be used to strip the store location and get
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
    mkEditableDirectLink = givenPath: let
      pathStr = toString givenPath;
      # Remove store prefix from given path (if any) so that:
      # given givenPath = ./foo
      # then  pathStr = "/nix/store/aaaaaaa-the-flake-source/path/to/foo"
      # then  pathRelativeToDots = "path/to/foo"
      pathRelativeToDots = lib.removePrefix ((toString cfg.flakeStorePath) + "/") pathStr;
    in
      # note: builtin `assert` does not have a msg...
      # https://github.com/NixOS/nix/issues/3233
      assert lib.asserts.assertMsg (cfg.dotfilesRepoPath != null && cfg.flakeStorePath != null) ''
        Options 'dotfilesRepoPath' and 'flakeStorePath' must be set for editable dyndots links
      '';
      # NOTE: Using mkOutOfStoreSymlink is necessary in home-manager (not in NixOS), it might be
      #   easier in the future: https://github.com/nix-community/home-manager/issues/3032
      config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesRepoPath}/${pathRelativeToDots}";
  in {
    dyndots.mkLink =
      if cfg.mode == "editable"
      then mkEditableDirectLink
      else mkStoreLink;
  };
}
