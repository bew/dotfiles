{ config, lib, pkgs, ... }:

let
  inherit (pkgs)
    fetchFromGitHub
    runCommandLocal
    stdenv
  ;
  mybuilders = pkgs.callPackage ../nix/mylib/mybuilders.nix {};
  cfg = config;
in {
  # Config ID, responsible for state & cache folders naming
  ID = "bew-nixified"; # !!! do not change unless you know what you're doing

  # Default bin dependencies
  # NOTE: bins are only made available in PATH, they won't be hardcoded in the config files
  #   (to ease config reloading)
  deps.bins = {
    git.pkg = pkgs.git;
    eza.pkg = pkgs.eza;
    direnv.pkg = pkgs.direnv;

    # Don't hardcode fzf in zoxide, will use the one in PATH
    zoxide.pkg = pkgs.zoxide.override { withFzf = false; };

    # bins used in fzf mappings (only)
    fzf.pkg = pkgs.fzf;
    fd.pkg = pkgs.fd;
    bat.pkg = pkgs.bat;
  } // (let
    coreutilsBin = binName: mybuilders.linkSingleBin "${pkgs.coreutils}/bin/${binName}";
  in {
    # coreutils bins
    # (only link bins we need to avoid mass bins pollution of the env closure)
    #
    # note: This is especially necessary on MacOS, where default set of base binaries are much
    #   simpler and don't support params I need…
    dircolors.pkg = coreutilsBin "dircolors";
    realpath.pkg = coreutilsBin "realpath"; # MacOS's `realpath` don't support `--relative-to`
    ls.pkg = coreutilsBin "ls"; # MacOS's `ls` don't support `--group-directories-first`
  });

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
        # Override buildPhase to work equally on Linux & MacOS (where gcc doesn't exist)
        buildPhase = /* sh */ ''
          $CC feeder.c -o feeder
        '';
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
    plugins = cfg.deps.plugins;
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
      --replace-fail "ZSH_MY_CONF_DIR=" "ZSH_MY_CONF_DIR=$out #" \
      --replace-fail "ZSH_CONFIG_ID=" "ZSH_CONFIG_ID=${cfg.ID} #" \
      \
      --replace-fail "source ~/.dot/shell/env.sh" "source ${../shell/env.sh}"
    # NOTE(!!!): last one is _TEMPORARY_ until we find a better way to inject cross-shell env script..

    >&2 echo "Patching binaries and plugins in .zshrc"
    substitute $src/zshrc $out/.zshrc \
      --replace-fail "_ZSH_PLUGIN_SRCREF__zsh_hooks=" "_ZSH_PLUGIN_SRCREF__zsh_hooks=${plugins.zsh-hooks} #" \
      --replace-fail "_ZSH_PLUGIN_SRCREF__zi="        "_ZSH_PLUGIN_SRCREF__zi=${plugins.zi} #" \
      --replace-fail "_ZSH_PLUGIN_SRCREF__F_Sy_H="    "_ZSH_PLUGIN_SRCREF__F_Sy_H=${plugins.F-Sy-H} #" \
      --replace-fail "_ZSH_PLUGIN_SRCREF__autopair="  "_ZSH_PLUGIN_SRCREF__autopair=${plugins.zsh-autopair} #" \
      --replace-fail "_ZSH_PLUGIN_SRCREF__gitstatus=" "_ZSH_PLUGIN_SRCREF__gitstatus=${plugins.gitstatus} #" \
      --replace-fail "_ZSH_PLUGIN_SRCREF__zconvey="   "_ZSH_PLUGIN_SRCREF__zconvey=${plugins.zconvey} #"
  '';
}
