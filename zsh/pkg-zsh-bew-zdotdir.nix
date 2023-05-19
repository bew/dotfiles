{
  lib,
  fetchFromGitHub,
  runCommand,
  stdenv,
  makeWrapper,
  coreutils,

  # plugins
  #zi, # only on unstable!
  zsh-autopair,
  zsh-z,
  gitstatus,

  # for fzf mappings
  fzf,
  fd,
  bat,
  git,
  ...
}:

let
  plugins = {
    zsh-z = "${zsh-z}/share/zsh-z";
    zsh-autopair = "${zsh-autopair}/share/zsh/zsh-autopair";
    gitstatus = "${gitstatus}/share/gitstatus";
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
      };
    in runCommand "zconvey" {} /* sh */ ''
      mkdir -p $out

      echo "Copying plugin files"
      cp -R ${zconvey-src}/* $out/
      chmod +w $out/feeder

      echo "Copying built feeder binary to plugin files"
      cp -v ${zconvey-feeder}/bin/feeder $out/feeder/feeder
    '';
  };

  bins = let
    binFromDrv = binName: drv: {
      outPath = "${drv}/bin/${binName}";
      manOutput = drv ? man;
    };
  in {
    # NOTE: one day all these will be Nix Flake Apps, so we can auto find the main bin :)
    fzf = binFromDrv "fzf" fzf;
    fd = binFromDrv "fd" fd;
    bat = binFromDrv "bat" bat;
    git = binFromDrv "git" git;
    dircolors = binFromDrv "dircolors" coreutils;
  };
  # NOTE: all bins from this list should also have their 'man' output installed!
  # not tested/used..
  binsManPages = lib.mapAttrsToList (_: binInfo: binInfo.manOutput) bins;
  # FIXME: How to propagate the 'man' outputs?
  # this looks like a job for the cliPkgModule system

in

runCommand "zsh-bew-zdotdir" {} /* sh */ ''
  mkdir -p $out $out/rc

  >&2 echo "Copying no-deps files"

  cp ${./.}/rc/aliases_and_short_funcs.zsh $out/rc/
  cp ${./.}/rc/completions.zsh $out/rc/
  cp ${./.}/rc/options.zsh $out/rc/
  cp ${./.}/rc/prompt.zsh $out/rc/

  # FIXME: this should be part of a sort of activation?
  # Or can I detect it's not set and suggest to run the activation command for that if it's not?
  cp ${./.}/fast-theme--bew.ini $out/

  ###cp -R ${./.}/completions $out/  # nothing important there
  ###cp -R ${./.}/fpath $out/        # nothing important there

  >&2 echo "Patching binaries in rc/mappings.zsh"
  cp ${./.}/rc/mappings.zsh $out/rc/
  substitute ${./rc/fzf-mappings.zsh} $out/rc/fzf-mappings.zsh \
    --replace "_BIN_fzf=" "_BIN_fzf=${bins.fzf} #" \
    --replace "_BIN_fd="  "_BIN_fd=${bins.fd} #" \
    --replace "_BIN_bat=" "_BIN_bat=${bins.bat} #" \
    --replace "_BIN_git=" "_BIN_git=${bins.git} #"

  >&2 echo "Patching config-specific env vars .zshenv"
  substitute ${./zshenv} $out/.zshenv \
    --replace "ZSH_MY_CONF_DIR=" "ZSH_MY_CONF_DIR=$out #" \
    --replace "ZSH_CONFIG_ID=" "ZSH_CONFIG_ID=bew-nixified #"

  >&2 echo "Patching binaries and plugins in .zshrc"
  substitute ${./zshrc} $out/.zshrc \
    --replace "_BIN_dircolors=" "_BIN_dircolors=${bins.dircolors} #" \
    \
    --replace "_ZSH_PLUGIN_SRCREF__zsh_hooks=" "_ZSH_PLUGIN_SRCREF__zsh_hooks=${plugins.zsh-hooks} #" \
    --replace "_ZSH_PLUGIN_SRCREF__zi="        "_ZSH_PLUGIN_SRCREF__zi=${plugins.zi} #" \
    --replace "_ZSH_PLUGIN_SRCREF__F_Sy_H="    "_ZSH_PLUGIN_SRCREF__F_Sy_H=${plugins.F-Sy-H} #" \
    --replace "_ZSH_PLUGIN_SRCREF__z="         "_ZSH_PLUGIN_SRCREF__z=${plugins.zsh-z} #" \
    --replace "_ZSH_PLUGIN_SRCREF__autopair="  "_ZSH_PLUGIN_SRCREF__autopair=${plugins.zsh-autopair} #" \
    --replace "_ZSH_PLUGIN_SRCREF__gitstatus=" "_ZSH_PLUGIN_SRCREF__gitstatus=${plugins.gitstatus} #" \
    --replace "_ZSH_PLUGIN_SRCREF__zconvey="   "_ZSH_PLUGIN_SRCREF__zconvey=${plugins.zconvey} #"
''
