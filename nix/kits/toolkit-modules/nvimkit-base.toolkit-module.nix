{ config, lib, pkgs, ... }:

let
  mypkglib = pkgs.callPackage ../../mypkglib.nix {};

  ty = lib.types;
  cfg = config;
  outs = cfg.outputs;

  makeNvimWrapperPkg =
    { extraWrapperParams ? "", fyiExtraDirs ? {} }:
    mypkglib.replaceBinsInPkg {
      name = "nvim-with-config-${cfg.ID}";
      copyFromPkg = cfg.package;
      nativeBuildInputs = [ pkgs.makeWrapper ];
      meta.mainProgram = "nvim";
      postBuild = /* sh */ ''
        makeWrapper ${cfg.package}/bin/nvim $out/bin/nvim \
          --prefix PATH : ${outs.deps.bins}/bin \
          ${lib.concatStringsSep " " (
            lib.mapAttrsToList (name: value: "--set ${name} ${lib.escapeShellArg value}") cfg.env
          )} \
          ${extraWrapperParams}
        # FYI, extra dirs (for easy access in the built derivation)
        ${if fyiExtraDirs != {} then "mkdir -p $out/useful-paths" else ""}
        ${
          lib.concatLines (let
            linker = name: dir_path: "ln -s ${lib.escapeShellArg dir_path} $out/useful-paths/${lib.escapeShellArg name}";
          in lib.mapAttrsToList linker fyiExtraDirs)
        }
      '';
    };

in {
  _class = "tool.nvim"; # type of nix module

  options = {
    initFile = lib.mkOption {
      description = "Init file to use for standalone bin generation";
      type = ty.nullOr ty.singleLineStr;
      default = (
        if cfg.dir.nvimdir.content ? "init.vim" then "init.vim"
        else if cfg.dir.nvimdir.content ? "init.lua" then "init.lua"
        else null
      );
    };

    env = lib.mkOption {
      description = "Env vars to set for this config";
      type = ty.attrsOf ty.str;
      default = {};
    };

    deps.plugins = lib.mkOption {
      description = "Vim plugins to install in DATA site dir (note: atm those are only 'opt' plugins)";
      type = ty.attrsOf ty.package;
      default = {};
    };
  };

  config = {
    package = lib.mkDefault pkgs.neovim;
    toolName = "nvim";

    dynamicConfig.isSupported = true;

    outputs.NVIM_APPNAME = "nvim-${lib.removePrefix "nvim-" cfg.ID}";

    dir.nvimdir.content = lib.mkDefault {};

    outputs.deps.pluginsDataSiteDir = pkgs.runCommandLocal "nvim-deps-dir-${cfg.ID}-site" {} ''
      packOptPlugins="$out/pack/nix-managed-plugins/opt"
      mkdir -p $packOptPlugins
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList
          (plugName: plugDrv: ''ln -s ${plugDrv} $packOptPlugins/${plugName}'')
          cfg.deps.plugins
      )}
    '';

    outputs.toolPkg.standalone = let
      xdgConfigDir = pkgs.runCommandLocal "nvim-dir-${cfg.ID}-xdg" {} ''
        # note: dirname of NVIM_APPNAME necessary to support NVIM_APPNAME like `nvim-foo/bar`
        mkdir -p $out/$(dirname "${outs.NVIM_APPNAME}")
        ln -s ${outs.dirs.nvimdir} $out/${outs.NVIM_APPNAME}
      '';
      xdgDataDir = pkgs.runCommandLocal "nvim-deps-dir-${cfg.ID}-xdg" {} ''
        mkdir -p "$out/${outs.NVIM_APPNAME}"
        ln -s ${outs.deps.pluginsDataSiteDir} $out/${outs.NVIM_APPNAME}/site
      '';
    in makeNvimWrapperPkg {
      fyiExtraDirs = {
        xdg_config = xdgConfigDir;
        xdg_data = xdgDataDir;
        bins_path = outs.deps.bins;
      };
      extraWrapperParams = ''
        --set NVIM_APPNAME ${outs.NVIM_APPNAME} \
        --prefix XDG_CONFIG_DIRS : ${xdgConfigDir} \
        --prefix XDG_DATA_DIRS : ${xdgDataDir} \
        ${lib.optionalString (cfg.initFile != null) ''--add-flags "-u ${outs.dirs.nvimdir}/${cfg.initFile}" ''}
      '';
    };

    # Tool is configured to point to config where it's installed in the system (it is NOT a standalone pkg)
    outputs.toolPkg.configured = makeNvimWrapperPkg {
      extraWrapperParams = ''--set NVIM_APPNAME ${outs.NVIM_APPNAME}'';
    };

    outputs.homeModules = let
      mkHomeModule = nvim_appname: {
        xdg.configFile.${nvim_appname}.source = outs.dirs.nvimdir;
        # NOTE: linking to 'site' because ..xdgData../NVIM_APPNAME might already exist on workstation
        xdg.dataFile."${nvim_appname}/site".source = outs.deps.pluginsDataSiteDir;
        home.packages = [
          (makeNvimWrapperPkg {
            fyiExtraDirs = {
              nvim_dir = outs.dirs.nvimdir;
              plugins_data_dir = outs.deps.pluginsDataSiteDir;
            };
            extraWrapperParams = ''
              --set NVIM_APPNAME ${nvim_appname}
            '';
          })
        ];
      };
    in {
      specific = mkHomeModule outs.NVIM_APPNAME;
      withDefaults = mkHomeModule "nvim";
    };
  };

}
