{
  buildEnv,
  lib,

  mybuilders,
  pkgs,
}:

let

  # This is a base module for declaring binary dependencies in a tool config.
  # TODO: move to a 'core' module when using it for other tools
  toolConfigBaseModule = { config, lib, pkgs, ... }: let
    ty = lib.types;
    binDependencyType = ty.submodule ({name, config, ...}: let
      subcfg = config;
    in {
      options = {
        binName = lib.mkOption {
          description = "Name of the binary we depend on in the *pkg*";
          type = ty.str;
          default = name;
        };
        pkg = lib.mkOption {
          description = "Derivation with the binary (optional)";
          type = ty.nullOr ty.package;
          default = null;
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
            description = "The derivation for the config env with config' dependencies";
            type = ty.package;
          };
        };
      };
    };
  };

  # Eval a tool config!
  # TODO: move to a 'core' module when using it for other tools
  mkToolConfig = {
    pkgs,
    toolName,
    configuration,
  }: let
    resolved = lib.evalModules {
      specialArgs.pkgs = pkgs;
      modules = [
        toolConfigBaseModule
        configuration
      ];
      class = "toolConfig.${toolName}";
    };
  in resolved.config;

  # -------------------------------------------------------------

  zshConfigBaseModule = { config, lib, pkgs, ... }: {
    _class = "toolConfig.zsh"; # type of nix module

    options = {
      outputs.zdotdir = lib.mkOption {
        description = "ZSH's config folder, with .zsh{rc,env} entrypoints";
        type = lib.types.package;
      };
    };

    config = {
      package = lib.mkDefault pkgs.zsh;

      outputs.depsEnv = pkgs.buildEnv {
        name = "config-deps-env-${config.ID}";
        paths = lib.mapAttrsToList (_key: dep: dep.pkg) config.deps.bins;
      };
      # FIXME: What exactly to expose to the zsh config?
      #   - Whole env with whole packages of dependencies?
      #   - Only bins? (but I loose man pages, completions, ..)
      # => When building a standalone package, make a full env with whole packages and put in PATH
      # => When making a homeManager module, it should blend the bin deps into the home config's
      #    packages and use overriden bins if any (HOW?)

      # Standalone zsh binary with the config
      outputs.zsh-standalone-pkg = mybuilders.replaceBinsInPkg {
        name = "zsh-bew";
        copyFromPkg = config.package;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        meta.mainProgram = "zsh";
        postBuild = /* sh */ ''
          makeWrapper ${config.package}/bin/zsh $out/bin/zsh \
            --set ZDOTDIR ${config.outputs.zdotdir} \
            --set SHELL_CLI_ENV ${config.outputs.depsEnv}
        '';
      };
    };
  };

in {
  zshConfigModule.zsh-bew = {
    imports = [
      zshConfigBaseModule
      ./zsh-bew.zsh-config-module.nix
    ];
  };

  lib.mkZshConfig = { pkgs, configuration }: (
    mkToolConfig {
      inherit pkgs configuration;
      toolName = "zsh";
    }
  );

  lib.mkZshPackages = zshConfig: {
    zsh-bew = zshConfig.outputs.zsh-standalone-pkg;
    zsh-bew-zdotdir = zshConfig.outputs.zdotdir;
    zsh-bew-bin = mybuilders.linkSingleBin (lib.getExe zshConfig.outputs.zsh-standalone-pkg);
  };

  # TODO: blend/propagate config binaries deps into chosen home config & chosen binaries..
  #   => Need a separate home module to represent home bins and the ones to choose..
  #      Then we can 'register' zshConfig.deps.bins into that and let it do some magic 😉
  # NOTE(!!): Currently it _IMPLICITELY_ work because `fzf-bew` is installed in my cli home config
  # (in <../nix/homes/cli.nix>), and the zsh config then finds it in its PATH.
  # |
  # BUT I want instead a direct dependency and a global override of the `fzf` binary
  # (=> might not be at home config level since I also want it at dotfiles' flake pkgs level..?)
  lib.mkZshHomeModule = zshConfig: let
    zdotdir = zshConfig.outputs.zdotdir;
  in {
    # This module installs my config in ~, using usual config files discovery of zsh in home
    # (`~/.zshrc` & `~/.zshenv`).
    # => Every config change still require a home rebuild & activation, but it's less hardcoded
    # than if the package itself had an internal reference to a specific zdotdir,
    # which would make reloading shell config (to use new one) from existing shells much harder.
    home.packages = [ zshConfig.package ];
    home.file.".zshrc".text = ''
      ZDOTDIR=${zdotdir}
      source ${zdotdir}/.zshrc
    '';
    home.file.".zshenv".text = ''
      source ${zdotdir}/.zshenv
    '';
    # FIXME: Add `.zlogin` ?
  };

}
