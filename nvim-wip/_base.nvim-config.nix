{ config, lib, pkgs, ... }:

let
  mybuilders = pkgs.callPackage ../nix/homes/mylib/mybuilders.nix {};

  ty = lib.types;
  cfg = config;
  outs = cfg.outputs;

  makeNvimWrapperPkg =
    { binName ? "nvim", extraWrapperParams ? "" }:
    mybuilders.replaceBinsInPkg {
      name = "nvim-with-config-${cfg.ID}";
      copyFromPkg = cfg.package;
      nativeBuildInputs = [ pkgs.makeWrapper ];
      meta.mainProgram = binName;
      postBuild = /* sh */ ''
        makeWrapper ${cfg.package}/bin/nvim $out/bin/${binName} \
          --prefix PATH : ${outs.deps.bins}/bin \
          ${extraWrapperParams}
      '';
    };

in {
  _class = "toolConfig.nvim"; # type of nix module

  options = {
    nvimDirSource = lib.mkOption {
      description = "Source for the nvim dir, if set `nvimDir.*` options are not used";
      type = ty.nullOr ty.path;
      default = null;
    };
    nvimDir = lib.mkOption {
      description = "Files in a nvim dir";
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
              cat > "$out/${spec.path}" <<-EOF
              ${spec.text}
              EOF
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
      if cfg.nvimDirSource != null then cfg.lib.mkLink cfg.nvimDirSource
      else nvimDirGenerated
    );

    outputs.toolPkg.standalone = let
      nvim_appname = "nvim-${lib.removePrefix "nvim-" cfg.ID}";
      xdgConfigDir = pkgs.runCommandLocal "nvim-dir-${cfg.ID}-xdg" {} ''
        # note: dirname of NVIM_APPNAME necessary to support NVIM_APPNAME like `nvim-foo/bar`
        mkdir -p $out/$(dirname "${nvim_appname}")
        ln -s ${outs.nvimDir} $out/${nvim_appname}
      '';
    in makeNvimWrapperPkg {
      extraWrapperParams = ''
        --set NVIM_APPNAME ${nvim_appname} \
        --prefix XDG_CONFIG_DIRS : ${xdgConfigDir} \
        ${lib.optionalString (cfg.initFile != null) ''--add-flags "-u ${outs.nvimDir}/${cfg.initFile}" ''}
      '';
    };

    outputs.homeModules.specific = let
      nvim_appname = "nvim-${lib.removePrefix "nvim-" cfg.ID}";
      nvim_binname = nvim_appname;
    in {
      xdg.configFile.${outs.NVIM_APPNAME}.source = outs.nvimDir;
      home.packages = [
        (makeNvimWrapperPkg {
          binName = nvim_appname;
          extraWrapperParams = ''
            --set NVIM_APPNAME ${nvim_appname}
          '';
        })
      ];
    };
    outputs.homeModules.withDefaults = {
      xdg.configFile."nvim".source = outs.nvimDir;
      home.packages = [ (makeNvimWrapperPkg {}) ];
    };
  };

}
