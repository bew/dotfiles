{
  fetchFromGitHub,
  runCommand,
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
    # FIXME: zconvey is broken, because it needs a tiny binary, usually compiled on first use of the plugin
    # => TODO: Make a drv to build that binary!
    zconvey = fetchFromGitHub {
      owner = "z-shell";
      repo = "zconvey";
      rev = "dd1060bf340cd0862ee8e158a6450c3196387096"; # latest master @2022-10
      hash = "sha256-n65PQ7l7CdS3zl+BtLSjJlTsWmdnLVmlDyl7rOwDw24=";
    };
  };

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
    --replace "_BIN_fzf=" "_BIN_fzf=${fzf}/bin/fzf #" \
    --replace "_BIN_fd="  "_BIN_fd=${fd}/bin/fd #" \
    --replace "_BIN_bat=" "_BIN_bat=${bat}/bin/bat #"

  >&2 echo "Patching config-specific env vars .zshenv"
  substitute ${./zshenv} $out/.zshenv \
    --replace "ZSH_MY_CONF_DIR=" "ZSH_MY_CONF_DIR=$out #" \
    --replace "ZSH_CONFIG_ID=" "ZSH_CONFIG_ID=bew-nixified #"

  >&2 echo "Patching binaries and plugins in .zshrc"
  substitute ${./zshrc} $out/.zshrc \
    --replace "_BIN_dircolors=" "_BIN_dircolors=${coreutils}/bin/dircolors #" \
    \
    --replace "_ZSH_PLUGIN_SRCREF__zsh_hooks=" "_ZSH_PLUGIN_SRCREF__zsh_hooks=${plugins.zsh-hooks} #" \
    --replace "_ZSH_PLUGIN_SRCREF__zi="        "_ZSH_PLUGIN_SRCREF__zi=${plugins.zi} #" \
    --replace "_ZSH_PLUGIN_SRCREF__F_Sy_H="    "_ZSH_PLUGIN_SRCREF__F_Sy_H=${plugins.F-Sy-H} #" \
    --replace "_ZSH_PLUGIN_SRCREF__z="         "_ZSH_PLUGIN_SRCREF__z=${plugins.zsh-z} #" \
    --replace "_ZSH_PLUGIN_SRCREF__autopair="  "_ZSH_PLUGIN_SRCREF__autopair=${plugins.zsh-autopair} #" \
    --replace "_ZSH_PLUGIN_SRCREF__gitstatus=" "_ZSH_PLUGIN_SRCREF__gitstatus=${plugins.gitstatus} #" \
    --replace "_ZSH_PLUGIN_SRCREF__zconvey="   "_ZSH_PLUGIN_SRCREF__zconvey=${plugins.zconvey} #"
''
