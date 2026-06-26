{ config, lib, pkgs, ... }:

let
  mybuilders = pkgs.callPackage ../../mylib/mybuilders.nix {};

  ty = lib.types;
  cfg = config;
  outs = config.outputs;
in {
  _class = "tool.tmux"; # type of nix module

  options = let
    configDirOption = lib.mkOption {
      description = "Tmux config dir";
      type = ty.package;
    };
  in {
    outputs.cfgDir = configDirOption;
    outputs.editable-cfgDir = configDirOption;
    outputs.non-editable-cfgDir = configDirOption;

    # TODO: move to base toolkit? 🤔
    # (might need more flexibility, decide where to inject / maybe in upcoming wrapper-kit?)
    env = lib.mkOption {
      description = "Configure wrapper environment vars";
      type = ty.attrsOf (ty.submodule {
        options.set = lib.mkOption {
          description = "add VAR with value VAL to the executable's environment";
          type = ty.nullOr ty.str;
          default = null;
        };
        options.set-default = lib.mkOption {
          description = "like `set`, but only adds VAR if not already set in the environment";
          type = ty.nullOr ty.str;
          default = null;
        };
      });
      default = {};
    };
  };

  config = {
    package = lib.mkDefault pkgs.tmux;
    toolName = "tmux";

    editable.isSupported = true;

    outputs.cfgDir = lib.mkMerge [
      (lib.mkIf config.editable.isEffectivelyEnabled cfg.outputs.editable-cfgDir)
      (lib.mkIf (!config.editable.isEffectivelyEnabled) cfg.outputs.non-editable-cfgDir)
    ];
    outputs.cfgEntrypoint = "${outs.cfgDir}/tmux.conf";

    outputs.toolPkg.standalone = mybuilders.replaceBinsInPkg (let
      binName = "tmux"; # for now, until I fix my `tx` alias, when used in `nix run dots`… 👀
      # binName = "tmux-${config.ID}";
    in {
      name = binName;
      copyFromPkg = config.package;
      nativeBuildInputs = [ pkgs.makeWrapper ];
      meta.mainProgram = binName;
      postBuild = /* sh */ ''
        wrapperArgs=(
          # Start tmux with custom config entrypoint
          --add-flags "-f ${outs.cfgEntrypoint}"
          # Send env var for config reloads
          --set TMUX_CONFIG_ENTRYPOINT ${outs.cfgEntrypoint}
          # Inject other env vars
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: valSpec:
            if valSpec.set != null then
              "--set ${name} ${lib.escapeShellArg valSpec.set}"
            else if valSpec.set-default != null then
              "--set-default ${name} ${lib.escapeShellArg valSpec.set-default}"
            else
              throw "tmux-toolkit: env.${name}: action not supported ☹️"
          ) cfg.env)}
          --prefix TERMINFO_DIRS : ${config.package.terminfo}/share/terminfo
        )
        makeWrapper ${cfg.package}/bin/tmux $out/bin/${binName} "''${wrapperArgs[@]}"
      '';
      # NOTE: we need to prepend terminfo to ensure the programs running in tmux find the correct
      #   terminfo database for the running tmux. (and not an eventual outdated system version)
      # -> This is necessary on MacOS to make colored underline work in Neovim under tmux.
      #    ref: https://github.com/neovim/neovim/issues/29649
    });

    outputs.homeModules.withDefaults = {
      xdg.configFile."tmux".source = outs.cfgDir;
      home.packages = [ config.package ];
    };
  };
}
