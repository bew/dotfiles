{ config, lib, pkgs, ... }:

let
  mybuilders = pkgs.callPackage ../nix/mylib/mybuilders.nix {};

  ty = lib.types;
  cfg = config;
  outs = cfg.outputs;

  makeNvimWrapperPkg =
    { extraWrapperParams ? "", fyiExtraDirs ? {} }:
    let
      binName = if cfg.useDefaultBinName then "nvim" else outs.NVIM_APPNAME;
    in
    mybuilders.replaceBinsInPkg {
      name = "nvim-with-config-${cfg.ID}";
      copyFromPkg = cfg.package;
      nativeBuildInputs = [ pkgs.makeWrapper ];
      meta.mainProgram = binName;
      postBuild = /* sh */ ''
        makeWrapper ${cfg.package}/bin/nvim $out/bin/${binName} \
          --prefix PATH : ${outs.deps.bins}/bin \
          ${lib.concatStringsSep " " (
            lib.mapAttrsToList (name: value: "--set ${name} ${lib.escapeShellArg value}") cfg.env
          )} \
          ${extraWrapperParams}
        # FYI, extra dirs (for easy access in the built derivation)
        ${if fyiExtraDirs != {} then "mkdir -p $out/fyi_extra_dirs" else ""}
        ${
          lib.concatLines (let
            linker = name: dir_path: "ln -s ${lib.escapeShellArg dir_path} $out/fyi_extra_dirs/${lib.escapeShellArg name}";
          in lib.mapAttrsToList linker fyiExtraDirs)
        }
      '';
    };

in {
  _class = "tool.nvim"; # type of nix module

  options = {
    nvimDirSource = lib.mkOption {
      description = "Source for the nvim dir (if set, `nvimDir.*` options are NOT used)";
      type = ty.nullOr ty.path;
      default = null;
    };
    nvimDir = lib.mkOption {
      description = "Files in a nvim config dir";
      type = ty.attrsOf (ty.submodule ({name, ...}: {
        options.path = lib.mkOption {
          type = ty.singleLineStr;
          default = name;
          internal = true;
        };
        options.text = lib.mkOption {
          description = "Content of the file";
          type = ty.nullOr ty.str;
          default = null;
        };
        options.source = lib.mkOption {
          description = "Source (file/dir/..) of the file/dir to symlink";
          type = ty.nullOr ty.path;
          default = null;
        };
        # TODO: add `options.replacements`
      }));
    };
    initFile = lib.mkOption {
      description = "Init file to use for standalone bin generation";
      type = ty.nullOr ty.singleLineStr;
      default = (
        if cfg.nvimDir ? "init.vim" then "init.vim"
        else if cfg.nvimDir ? "init.lua" then "init.lua"
        else null
      );
    };

    env = lib.mkOption {
      description = "Env vars to set for this config";
      type = ty.attrsOf ty.str;
      default = {};
    };

    useDefaultBinName = lib.mkOption {
      description = "Whether outputs should use the default bin name or a config-specific one";
      type = ty.bool;
      default = false;
    };

    deps.plugins = lib.mkOption {
      description = "Vim plugins to install in DATA site dir (note: atm the those are only 'opt' plugins)";
      type = ty.attrsOf ty.package;
      default = {};
    };
  };

  config = {
    package = lib.mkDefault pkgs.neovim;
    toolName = "nvim";

    outputs.NVIM_APPNAME = "nvim-${lib.removePrefix "nvim-" cfg.ID}";

    # TODO: this is mostly nvim-agnostic, could extract to a dir-builder module 🤔
    outputs.nvimDir = let
      nvimDirGenerated = pkgs.runCommandLocal "nvim-dir-${cfg.ID}" {} (let
        pathSpecs = lib.attrValues cfg.nvimDir;
        specToAction = spec: (
          if spec.text != null then
            ''
              echo "Adding path '${spec.path}' (text)"
              mkdir -p "$out/$(dirname "${spec.path}")"
              cat > "$out/${spec.path}" <<-EndOfTheFile
              ${spec.text}
              EndOfTheFile
            ''
          else if spec.source != null then
            ''
              echo "Adding path '${spec.path}' (link)"
              mkdir -p "$out/$(dirname "${spec.path}")"
              ln -s "${cfg.lib.mkLink spec.source}" "$out/${spec.path}"
            ''
          else
            throw "unsupported spec for path '${spec.path}'"
        );
      in lib.concatMapStringsSep "\n" specToAction pathSpecs);
    in (
      if cfg.nvimDirSource != null
      then cfg.lib.mkLink cfg.nvimDirSource
      else nvimDirGenerated
    );

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
        ln -s ${outs.nvimDir} $out/${outs.NVIM_APPNAME}
      '';
      xdgDataDir = pkgs.runCommandLocal "nvim-deps-dir-${cfg.ID}-xdg" {} ''
        mkdir -p "$out/${outs.NVIM_APPNAME}"
        ln -s ${outs.deps.pluginsDataSiteDir} $out/${outs.NVIM_APPNAME}/site
      '';
    in makeNvimWrapperPkg {
      fyiExtraDirs = {
        xdg_config = xdgConfigDir;
        xdg_data = xdgDataDir;
      };
      extraWrapperParams = ''
        --set NVIM_APPNAME ${outs.NVIM_APPNAME} \
        --prefix XDG_CONFIG_DIRS : ${xdgConfigDir} \
        --prefix XDG_DATA_DIRS : ${xdgDataDir} \
        ${lib.optionalString (cfg.initFile != null) ''--add-flags "-u ${outs.nvimDir}/${cfg.initFile}" ''}
      '';
    };

    # Tool is configured to point to config where it's installed in the system (it is NOT a standalone pkg)
    outputs.toolPkg.configured = makeNvimWrapperPkg {
      extraWrapperParams = ''--set NVIM_APPNAME ${outs.NVIM_APPNAME}'';
    };

    outputs.homeModules = let
      mkHomeModule = nvim_appname: {
        xdg.configFile.${nvim_appname}.source = outs.nvimDir;
        # NOTE: linking to 'site' because ..xdgData../NVIM_APPNAME might already exist on workstation
        xdg.dataFile."${nvim_appname}/site".source = outs.deps.pluginsDataSiteDir;
        home.packages = [
          (makeNvimWrapperPkg {
            fyiExtraDirs = {
              nvim_dir = outs.nvimDir;
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
