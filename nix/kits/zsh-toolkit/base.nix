{ config, lib, pkgs, ... }:

let
  mypkglib = pkgs.callPackage ../../mypkglib.nix {};

  ty = lib.types;
  cfg = config;
  outs = cfg.outputs;
in {
  _class = "tool.zsh"; # type of nix module

  options = {
    outputs.zdotdir = lib.mkOption {
      description = "ZSH's config folder, with .zsh{rc,env} entrypoints";
      type = ty.package;
    };
    outputs.zdotdir-hash = lib.mkOption {
      description = "The Nix hash of the built 'zdotdir' output";
      type = ty.singleLineStr;
      default = builtins.substring 0 32 (builtins.baseNameOf cfg.outputs.zdotdir);
      readOnly = true;
    };
  };

  config = {
    package = lib.mkDefault pkgs.zsh;
    toolName = "zsh";

    # FIXME: What exactly to expose to the zsh config?
    #   - Whole env with whole packages of dependencies?
    #   - Only bins? (but I loose man pages, completions, ..)
    # => When building a standalone package, make a full env with whole packages and put in PATH
    # => When making a homeManager module, it should blend the bin deps into the home config's
    #    packages and use overriden bins if any (HOW?)

    # Standalone zsh binary with the config
    outputs.toolPkg.standalone = mypkglib.replaceBinsInPkg {
      name = "zsh-bew"; # FIXME: this should be `zsh-with-config-{ID}` 🤔
      copyFromPkg = cfg.package;
      nativeBuildInputs = [ pkgs.makeWrapper ];
      meta.mainProgram = "zsh";
      postBuild = /* sh */ ''
        makeWrapper ${cfg.package}/bin/zsh $out/bin/zsh \
          --set ZDOTDIR ${outs.zdotdir} \
          --set ZSH_CONFIG_HASH ${outs.zdotdir-hash} \
          --set SHELL_CLI_ENV ${outs.deps.bins}
      '';
    };

    # TODO: blend/propagate config binaries deps into chosen home config & chosen binaries..
    #   => Need a separate home module to represent home bins and the ones to choose..
    #      Then we can 'register' cfg.deps.bins into that and let it do some magic 😉
    # NOTE(!!): Currently it _IMPLICITELY_ work because `fzf-bew` is installed in my cli home
    # config (in <../nix/homes/cli.nix>), and the zsh config then finds it in its PATH.
    # |
    # BUT I want instead a direct dependency and a global override of the `fzf` binary
    # (=> might not be at home config level since I also want it at dotfiles' flake pkgs level..?)
    outputs.homeModules.withDefaults = {
      # This module installs my config in ~, using usual config files discovery of zsh in home
      # (`~/.zshrc` & `~/.zshenv`).
      # => Every config change still require a home rebuild & activation, but it's less hardcoded
      # than if the package itself had an internal reference to a specific zdotdir,
      # which would make reloading shell config (to use new one) from existing shells much harder.
      home.packages = [
        cfg.package
        outs.deps.bins
      ];
      home.file.".zshrc".text = ''
        ZDOTDIR=${outs.zdotdir}
        ZSH_CONFIG_HASH=${outs.zdotdir-hash}
        source ${outs.zdotdir}/.zshrc
      '';
      home.file.".zshenv".text = ''
        source ${outs.zdotdir}/.zshenv
      '';
      # FIXME: Add `.zlogin` ?
    };
  };
}
