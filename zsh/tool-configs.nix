{
  buildEnv,
  lib,

  mybuilders,
  pkgs,
}:

let

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
        name = "zsh-config-deps-env-${config.ID}";
        paths = let
          # NOTE: a bin dep without pkg finds its binary in PATH, not in a known pkg at this level.
          #   Here we're only interested in binaries with a pkg.
          # (TODO(maybe): find a way to check that all bins are available in PATH?)
          binsWithPkg = lib.filterAttrs (_name: dep: dep.pkg != "from-PATH") config.deps.bins;
        in lib.mapAttrsToList (_name: dep: dep.pkg) binsWithPkg;
      };
      # FIXME: What exactly to expose to the zsh config?
      #   - Whole env with whole packages of dependencies?
      #   - Only bins? (but I loose man pages, completions, ..)
      # => When building a standalone package, make a full env with whole packages and put in PATH
      # => When making a homeManager module, it should blend the bin deps into the home config's
      #    packages and use overriden bins if any (HOW?)

      # Standalone zsh binary with the config
      outputs.toolWithConfig = mybuilders.replaceBinsInPkg {
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

      # TODO: blend/propagate config binaries deps into chosen home config & chosen binaries..
      #   => Need a separate home module to represent home bins and the ones to choose..
      #      Then we can 'register' zshConfig.deps.bins into that and let it do some magic 😉
      # NOTE(!!): Currently it _IMPLICITELY_ work because `fzf-bew` is installed in my cli home
      # config (in <../nix/homes/cli.nix>), and the zsh config then finds it in its PATH.
      # |
      # BUT I want instead a direct dependency and a global override of the `fzf` binary
      # (=> might not be at home config level since I also want it at dotfiles' flake pkgs level..?)
      outputs.primaryHomeManagerModule = let
        zshConfig = config; # ref to outer module
        zdotdir = zshConfig.outputs.zdotdir;
      in {
        # This module installs my config in ~, using usual config files discovery of zsh in home
        # (`~/.zshrc` & `~/.zshenv`).
        # => Every config change still require a home rebuild & activation, but it's less hardcoded
        # than if the package itself had an internal reference to a specific zdotdir,
        # which would make reloading shell config (to use new one) from existing shells much harder.
        home.packages = [
          zshConfig.package
          zshConfig.outputs.depsEnv
        ];
        home.file.".zshrc".text = ''
          ZDOTDIR=${zdotdir}
          source ${zdotdir}/.zshrc
        '';
        home.file.".zshenv".text = ''
          source ${zdotdir}/.zshenv
        '';
        # FIXME: Add `.zlogin` ?
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

  lib.evalZshConfig = { pkgs, configuration }: let
    toolConfigsFactory = import ./../nix/tool-configs-factory { inherit lib; };
  in toolConfigsFactory.lib.evalToolConfig {
    inherit pkgs configuration;
    toolName = "zsh";
  };
}
