# This is a base module for declaring the config of a tool (with ID, declarative dependencies, outputs...)
{ config, lib, pkgs, ... }:

let
  ty = lib.types;
  cfg = config;

  binDependencyType = ty.submodule ({name, config, ...}: let
    subcfg = config;
  in {
    options = {
      binName = lib.mkOption {
        description = "Name of the binary we depend on in the *pkg* (defaults to attr name)";
        type = ty.singleLineStr;
        default = name;
      };
      pkg = lib.mkOption {
        description = "Derivation having the binary (optional)";
        type = ty.either (ty.strMatching "from-PATH") ty.package;
        default = "from-PATH";
      };
    };
  });
in {
  options = {
    ID = lib.mkOption {
      description = "Config ID (should be unique), usually used for state/cache folders naming";
      type = ty.strMatching "[a-zA-Z_-]+";
    };
    toolName = lib.mkOption {
      description = "Name of the tool, used to name some default pkg";
      type = ty.singleLineStr;
    };
    lib = lib.mkOption {
      description = "Set of lib functions to help write configs";
      type = ty.attrsOf (ty.uniq ty.anything);
    };
    package = lib.mkOption {
      description = "The package of the tool being configured";
      type = ty.package;
    };
    deps = lib.mkOption {
      # NOTE: inspired by NixOS's `system.build` defined in <nixpkgs/nixos/modules/system/build.nix>
      description = ''
        Attribute set of dependencies by types for the config
      '';
      type = ty.submodule {
        freeformType = ty.lazyAttrsOf (ty.uniq ty.anything);
        options.bins = lib.mkOption {
          # NOTE: this aims to be used by config & caller to setup proper binaries for the config context.
          type = ty.attrsOf (binDependencyType);
          default = {};
        };
      };
      default = {};
    };
    outputs = lib.mkOption {
      # NOTE: inspired by NixOS's `system.build` defined in <nixpkgs/nixos/modules/system/build.nix>
      description = ''
        Attribute set(s) of output derivations for the config (specific to tool being configured)
      '';
      type = ty.submodule {
        freeformType = ty.lazyAttrsOf (ty.uniq ty.anything);
        options.deps.bins = lib.mkOption {
          description = "Derivation for the config env with config' dependencies";
          type = ty.package;
        };
        options.toolPkg.standalone = lib.mkOption {
          description = "Derivation of the tool being configured, where tool binary is pre-configured with the config and usable by itself";
          type = ty.package;
        };
        # NOTE: This can only be used ONCE in a home config since it takes over default config paths.
        options.homeModules.withDefaults = lib.mkOption {
          description = ''
            Home Manager module that adds the tool and its primary config in tool's default config paths.
            This module can only be used ONCE in a Home Manager config.
          '';
          # type = ty.package; # FIXME: how to type a Nix module (with class check?) ??
        };
        options.homeModules.specific = lib.mkOption {
          description = ''
            Home Manager module that adds the tool and its config in config-ID-specific paths.
            This module should be usable MULTIPLE in a Home Manager config.
          '';
          # type = ty.package; # FIXME: how to type a Nix module (with class check?) ??
        };
      };
    };
  };

  config = {
    # Function (overridable) used to get the target of a symlink, to a (potentially editable) file/dir.
    # Defaults to copy to store (not editable).
    lib.mkLink = lib.mkDefault (path: "${path}");

    outputs.deps.bins = pkgs.buildEnv {
      name = "${cfg.toolName}-config-deps-bins-${cfg.ID}";
      paths = let
        binsWithPkg = lib.filterAttrs (_name: dep: dep.pkg != "from-PATH") config.deps.bins;
      in lib.mapAttrsToList (_name: dep: dep.pkg) binsWithPkg;
    };
  };
}
