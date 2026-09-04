{ pkgsets, lib, mypkglib, pkgs, kitConfigs, ... }:

let
  inherit (pkgsets) stable bleedingedge mypkgs;

  # NOTE: tentative at a global list of cli tools, referenced in other tools as needed..
  #
  # TODO: need to make a proper module, potentially at higher level than the home config?..
  #   (see comment above homeModules.withDefaults in </zsh/tool-configs.nix> for thoughts on bins deps propagation..)
  # FIXME: remove this! (but where to put that comment above??)
  cliPkgs = {
    fzf = mypkgs.fzf-bew;
  };

in {
  imports = [
    ../../presets/home/cli-neovim.nix

    ../../presets/home/cli-direnv.nix
    ../../presets/home/cli-git-stuff.nix

    # FIXME: find a way to not have to import those here 🤔
    kitConfigs.zsh-bew.outputs.homeModules.withDefaults
    kitConfigs.tmux-bew.outputs.homeModules.withDefaults
  ];

  home.packages = [
    # alternative ls, more colors!
    (stable.eza.overrideAttrs (final: prev: {
      doCheck = false;
      patches = prev.patches ++ [
        (pkgs.fetchpatch {
          # Commit: fix(color-scale): use file size unit custom color when not using color scale
          # PR: https://github.com/eza-community/eza/pull/975
          url = "https://github.com/eza-community/eza/commit/c7493753fbf8d572703a782941cf134357dd740a.patch";
          hash = "sha256-lmXGt20l6o5tbNXDicq17sBCt36qckV8XX7EJ2Gi3vQ=";
        })
      ];
    }))

    cliPkgs.fzf
    stable.bat
    stable.fd
    stable.trashy
    stable.jq
    stable.yq
    stable.sd # nicer sed for ~simple search/replace
    stable.ripgrep
    stable.tree
    stable.just
    stable.eva # nice calculator

    stable.less

    stable.yazi
    stable.ncdu
    stable.htop
    stable.tealdeer # tldr, examples for many programs (offline once DB cached)

    stable.entr
    stable.tokei

    stable.units # gnu's unit converter, has MANY units (https://www.gnu.org/software/units/)
    # Best alias: units -1 --compact FROM-UNIT TO-UNIT

    # network tools
    (mypkglib.linkBins "doggo-as-dig" { dig = "${stable.doggo}/bin/doggo"; }) # nicer `dig`
    stable.netcat-openbsd # for `nc`
    stable.xh # httpie but fasterrr
    bleedingedge.resterm # nice TUI REST HTTP client
  ];
}
