{
  fetchFromGitHub,
  runCommand,
  makeWrapper,
  coreutils,
  zsh,

  # plugins
  #zi, # only on unstable!
  zsh-autopair,
  zsh-z,
  gitstatus,

  # for fzf mappings
  fzf,
  fd,
  bat,
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
    zconvey = fetchFromGitHub {
      owner = "z-shell";
      repo = "zconvey";
      rev = "dd1060bf340cd0862ee8e158a6450c3196387096"; # latest master @2022-10
      hash = "sha256-n65PQ7l7CdS3zl+BtLSjJlTsWmdnLVmlDyl7rOwDw24=";
    };
  };

  cfg_files = {
    zshrc = runCommand "zshrc" {} /* sh */ ''
      out_zshrc=$out
      cp ${./zshrc} $out_zshrc
      substituteInPlace $out_zshrc \
        --replace "_BIN_dircolors=" "_BIN_dircolors=${coreutils}/bin/dircolors #"
      substituteInPlace $out_zshrc \
        --replace "_ZSH_PLUGIN_SRCREF__zsh_hooks=" "_ZSH_PLUGIN_SRCREF__zsh_hooks=${plugins.zsh-hooks} #" \
        --replace "_ZSH_PLUGIN_SRCREF__zi="        "_ZSH_PLUGIN_SRCREF__zi=${plugins.zi} #" \
        --replace "_ZSH_PLUGIN_SRCREF__F_Sy_H="    "_ZSH_PLUGIN_SRCREF__F_Sy_H=${plugins.F-Sy-H} #" \
        --replace "_ZSH_PLUGIN_SRCREF__z="         "_ZSH_PLUGIN_SRCREF__z=${plugins.zsh-z} #" \
        --replace "_ZSH_PLUGIN_SRCREF__autopair="  "_ZSH_PLUGIN_SRCREF__autopair=${plugins.zsh-autopair} #" \
        --replace "_ZSH_PLUGIN_SRCREF__gitstatus=" "_ZSH_PLUGIN_SRCREF__gitstatus=${plugins.gitstatus} #" \
        --replace "_ZSH_PLUGIN_SRCREF__zconvey="   "_ZSH_PLUGIN_SRCREF__zconvey=${plugins.zconvey} #"
    '';

    rc-fzf-mappings = runCommand "rc-fzf-mappings" {} /* sh */ ''
      out_mappings=$out
      cp ${./rc/fzf-mappings.zsh} $out_mappings
      substituteInPlace $out_mappings \
        --replace "_BIN_fzf=" "_BIN_fzf=${fzf}/bin/fzf #" \
        --replace "_BIN_fd="  "_BIN_fd=${fd}/bin/fd #" \
        --replace "_BIN_bat=" "_BIN_bat=${bat}/bin/bat #"
    '';
  };

  bew-config-zdotdir = runCommand "bew-config" {} /* sh */ ''
    mkdir -p $out $out/rc
    cp ${./.}/rc/aliases_and_short_funcs.zsh $out/rc/
    cp ${./.}/rc/completions.zsh $out/rc/
    cp ${cfg_files.rc-fzf-mappings} $out/rc/fzf-mappings.zsh
    cp ${./.}/rc/mappings.zsh $out/rc/
    cp ${./.}/rc/options.zsh $out/rc/
    cp ${./.}/rc/prompt.zsh $out/rc/
    #cp -R ${./.}/completions $out/  # nothing important there
    #cp -R ${./.}/fpath $out/        # nothing important there

    # FIXME: this should be part of a sort of activation?
    # Or can I detect it's not set and suggest to run the activation command for that if it's not?
    cp    ${./.}/fast-theme--bew.ini $out/

    cp    ${cfg_files.zshrc} $out/.zshrc
    cp    ${./.}/zshenv $out/.zshenv

    substituteInPlace $out/.zshenv \
      --replace "ZSH_MY_CONF_DIR=" "ZSH_MY_CONF_DIR=$out #" \
      --replace "ZSH_CONFIG_ID=" "ZSH_CONFIG_ID=bew-nixified #"
  '';
in {
  packages.zsh-bew = runCommand "zsh-bew" { nativeBuildInputs = [ makeWrapper ]; } /* sh */ ''
    mkdir -p $out/bin
    cp ${zsh}/bin/zsh $out/bin/zsh-bew
    wrapProgram $out/bin/zsh-bew --set ZDOTDIR ${bew-config-zdotdir}
  '';
}
# vim:set ft=conf sw=2:
