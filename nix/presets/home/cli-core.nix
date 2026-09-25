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
    eza = mypkgs.eza-bew;
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
    cliPkgs.eza # alternative ls, more colors!
    cliPkgs.fzf
    stable.bat
    stable.fd
    stable.jq
    stable.yq
    stable.sd # nicer sed for ~simple search/replace
    stable.ripgrep
    stable.tree
    stable.just
    stable.eva # nice calculator

    stable.less

    stable.bats # Bash-based testing tool, useful everywhere

    stable.yazi
    stable.ncdu
    stable.htop
    stable.tealdeer # tldr, examples for many programs (offline once DB cached)

    stable.entr # Run arbitrary commands when files change
    stable.tokei # Count your code, quickly.

    stable.units # gnu's unit converter, has MANY units (https://www.gnu.org/software/units/)
    # Best alias: units -1 --compact FROM-UNIT TO-UNIT

    # network tools
    (mypkglib.linkBins "doggo-as-dig" { dig = "${stable.doggo}/bin/doggo"; }) # nicer `dig`
    stable.xh # httpie but fasterrr
    bleedingedge.resterm # nice TUI REST HTTP client
  ];
}
