{ pkgsChannels, lib, mybuilders, pkgs, myToolConfigs, ... }:

let
  inherit (pkgsChannels) stable bleedingedge myPkgs;

  # NOTE: tentative at a global list of cli tools, referenced in other tools as needed..
  #
  # TODO: need to make a proper module, potentially at higher level than the home config?..
  #   (see comment above homeModules.withDefaults in </zsh/tool-configs.nix> for thoughts on bins deps propagation..)
  cliPkgs = {
    fzf = myPkgs.fzf-bew;
  };

in {
  imports = [
    myToolConfigs.zsh-bew.outputs.homeModules.withDefaults
    myToolConfigs.tmux-bew.outputs.homeModules.withDefaults

    ./cli/neovim.nix
    ./cli/direnv.nix
    ./cli/git-stuff.nix
  ];

  home.packages = [
    # alternative ls, more colors!
    (bleedingedge.eza.overrideAttrs (final: prev: {
      doCheck = false;
      patches = prev.patches ++ [
        (pkgs.fetchpatch {
          # Commit: fix(color-scale): use file size unit custom color when not using color scale
          # PR: https://github.com/eza-community/eza/pull/975
          url = "https://github.com/eza-community/eza/commit/e52c367a421c7109e23a4d69b8c5ba7882c1b20b.patch";
          hash = "sha256-kWR65F0LxqQp6LBP/TXLIzt1zFpgKT1jA3b4VvHfnUw=";
        })
      ];
    }))

    cliPkgs.fzf
    stable.bat
    stable.fd
    stable.trashy
    stable.jq
    stable.yq
    stable.ripgrep
    stable.tree
    stable.just
    stable.eva # nice calculator

    stable.less

    stable.yazi
    stable.ncdu
    stable.htop
    stable.tealdeer # tldr, examples for many programs (offline once DB cached)

    stable.ansifilter # Convert text with ANSI seqs to other formats (e.g: remove them)
    stable.entr
    stable.tokei

    stable.units # gnu's unit converter, has MANY units (https://www.gnu.org/software/units/)
    # Best alias: units -1 --compact FROM-UNIT TO-UNIT

    # network tools
    (mybuilders.linkBins "dogdns-as-dig" { dig = "${stable.dogdns}/bin/dog"; }) # nicer `dig`
    stable.netcat-openbsd # for `nc`
    stable.xh # httpie but fasterrr
  ];
}
