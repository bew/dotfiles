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
        makeWrapper ${cfg.package}/bin/tmux $out/bin/${binName} \
          --add-flags "-f ${outs.cfgEntrypoint}" \
          --set TMUX_CONFIG_ENTRYPOINT ${outs.cfgEntrypoint}
      '';
    });

    outputs.homeModules.withDefaults = {
      xdg.configFile."tmux".source = outs.cfgDir;
      home.packages = [ config.package ];
    };
  };
}
