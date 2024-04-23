# This is a base module for declaring the config of a tool (with ID, declarative dependencies, outputs...)
{ config, lib, pkgs, ... }:

let
  ty = lib.types;
  binDependencyType = ty.submodule ({name, config, ...}: let
    subcfg = config;
  in {
    options = {
      binName = lib.mkOption {
        description = "Name of the binary we depend on in the *pkg* (defaults to attr name)";
        type = ty.str;
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
      type = ty.str;
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
        freeformType = ty.lazyAttrsOf (ty.uniq ty.unspecified);
        options.bins = lib.mkOption {
          # NOTE: this aims to be used by config & caller to setup proper binaries for the config context.
          type = ty.attrsOf (binDependencyType);
        };
      };
    };
    outputs = lib.mkOption {
      # NOTE: inspired by NixOS's `system.build` defined in <nixpkgs/nixos/modules/system/build.nix>
      description = ''
        Attribute set(s) of output derivations for the config (specific to tool being configured)
      '';
      type = ty.submodule {
        freeformType = ty.lazyAttrsOf (ty.uniq ty.unspecified);
        options.depsEnv = lib.mkOption {
          # NOTE: This should be flexible to work with different kinds of deps 🤔
          description = "Derivation for the config env with config' dependencies";
          type = ty.package;
        };
        options.toolWithConfig = lib.mkOption {
          description = "Derivation of the tool being configured, where tool binary is pre-configured with the config";
          type = ty.package;
        };
        # NOTE: This can only be used ONCE in a home config since it takes over default config paths.
        options.primaryHomeManagerModule = lib.mkOption {
          description = ''
            Home Manager module that adds the tool and its primary config in tool's default config paths.
            This module can only be used ONCE in a Home Manager config.
          '';
          # type = ty.package; # FIXME: how to type a Nix module (with class check?) ??
        };
        # TODO(?): Add an output that can be used MULTIPLE times to setup multiple configs of the
        #   tool in a single home config 🤔
      };
    };
  };
}
