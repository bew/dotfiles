{ config, lib, pkgs, ... }:

let
  inherit (pkgs)
    fetchFromGitHub
    runCommandLocal
    stdenv
  ;
in {
  # Config ID, responsible for state & cache folders naming
  ID = "bew-nixified"; # !!! do not change unless you know what you're doing

  # Default bin dependencies
  # NOTE: bins are only made available in PATH, they won't be hardcoded in the config files
  #   (to ease config reloading)
  deps.bins = {
    git.pkg = pkgs.git;
    dircolors = {
      # FIXME: remove all non-dircolors bins?
      #   (coreutils pkg POLLUTES the depsEnv closure significantly even if we _only_ need dircolors bin..)
      pkg = pkgs.coreutils;
    };
    direnv.pkg = pkgs.direnv;
    zoxide.pkg = pkgs.zoxide;

    # bins used in fzf mappings (only)
    fzf.pkg = pkgs.fzf;
    fd.pkg = pkgs.fd;
    bat.pkg = pkgs.bat;
  };

  deps.plugins = {
    zsh-autopair = "${pkgs.zsh-autopair}/share/zsh/zsh-autopair";
    gitstatus = "${pkgs.gitstatus}/share/gitstatus";
    zi = fetchFromGitHub {
      owner = "z-shell";
      repo = "zi";
      rev = "d817cd7440c353300e7b5fd3f2cd18f34abb35aa"; # latest master @2022-10
      hash = "sha256-OMHmG+QnfsnOT3I8AmAqrVOD+M9uZ48dYxHqFNhY0mA=";
    };
    zsh-hooks = fetchFromGitHub {
      owner = "zsh-hooks";
      repo = "zsh-hooks";
      rev = "283346c132d61baa4c6b81961c217f9b238d023b"; # latest master @2022-10
      hash = "sha256-n33jaUlti1S2G2Oxc+KuMZcHqd2FO/knivHam47EK78=";
    };
    F-Sy-H = fetchFromGitHub {
      owner = "z-shell";
      repo = "F-Sy-H";
      rev = "v1.66";
      hash = "sha256-by5x/FTGhypk98w31WQrSUxJTStM39Z21DmMV7P4yVA=";
    };
    zconvey = let
      # NOTE: zconvey needs a tiny binary, the feeder, which is usually compiled in-place on
      # first use of the plugin but that's not possible with Nix since 'in-place' is read-only.
      zconvey-src = fetchFromGitHub {
        owner = "z-shell";
        repo = "zconvey";
        rev = "dd1060bf340cd0862ee8e158a6450c3196387096"; # latest master @2022-10
        hash = "sha256-n65PQ7l7CdS3zl+BtLSjJlTsWmdnLVmlDyl7rOwDw24=";
      };
      zconvey-feeder = stdenv.mkDerivation {
        name = "zconvey-feeder";
        src = "${zconvey-src}/feeder";
        installPhase = /* sh */ ''
          mkdir -p $out/bin
          mv feeder $out/bin/feeder
        '';
        meta.mainProgram = "feeder";
      };
    in runCommandLocal "zconvey" {} /* sh */ ''
      mkdir -p $out

      echo "Copying plugin files"
      cp -R ${zconvey-src}/* $out/
      chmod +w $out/feeder

      echo "Copying built feeder binary to plugin files"
      cp -v ${lib.getExe zconvey-feeder} $out/feeder/feeder
    '';
  };

  outputs.zdotdir = let
    plugins = config.deps.plugins;
  in runCommandLocal "zsh-bew-zdotdir" {
    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.unions [
        (lib.fileset.fileFilter (f: ! f.hasExt "nix") ./.) # skip all nix files
        ./rc
        ./fast-theme--bew.ini
        ./zshrc
        ./zshenv
        ./zlogin
      ];
    };
  } /* sh */ ''
    mkdir -p $out $out/rc

    >&2 echo "Copying no-deps files"

    cp $src/rc/aliases_and_short_funcs.zsh $out/rc/
    cp $src/rc/completions.zsh $out/rc/
    cp $src/rc/options.zsh $out/rc/
    cp $src/rc/prompt.zsh $out/rc/
    cp $src/rc/mappings.zsh $out/rc/
    cp $src/rc/fzf-mappings.zsh $out/rc/

    # FIXME: this should be part of a sort of activation?
    # Or can I detect it's not set and suggest to run the activation command for that if it's not?
    cp $src/fast-theme--bew.ini $out/

    ###cp -R $src/completions $out/  # nothing important there
    ###cp -R $src/fpath $out/        # nothing important there

    >&2 echo "Patching config-specific env vars in .zshenv"
    substitute $src/zshenv $out/.zshenv \
      --replace "ZSH_MY_CONF_DIR=" "ZSH_MY_CONF_DIR=$out #" \
      --replace "ZSH_CONFIG_ID=" "ZSH_CONFIG_ID=${config.ID} #" \
      \
      --replace "source ~/.dot/shell/env.sh" "source ${../shell/env.sh}"
    # NOTE(!!!): last one is _TEMPORARY_ until we find a better way to inject cross-shell env script..

    >&2 echo "Patching binaries and plugins in .zshrc"
    substitute $src/zshrc $out/.zshrc \
      --replace "_ZSH_PLUGIN_SRCREF__zsh_hooks=" "_ZSH_PLUGIN_SRCREF__zsh_hooks=${plugins.zsh-hooks} #" \
      --replace "_ZSH_PLUGIN_SRCREF__zi="        "_ZSH_PLUGIN_SRCREF__zi=${plugins.zi} #" \
      --replace "_ZSH_PLUGIN_SRCREF__F_Sy_H="    "_ZSH_PLUGIN_SRCREF__F_Sy_H=${plugins.F-Sy-H} #" \
      --replace "_ZSH_PLUGIN_SRCREF__autopair="  "_ZSH_PLUGIN_SRCREF__autopair=${plugins.zsh-autopair} #" \
      --replace "_ZSH_PLUGIN_SRCREF__gitstatus=" "_ZSH_PLUGIN_SRCREF__gitstatus=${plugins.gitstatus} #" \
      --replace "_ZSH_PLUGIN_SRCREF__zconvey="   "_ZSH_PLUGIN_SRCREF__zconvey=${plugins.zconvey} #"
  '';
}
