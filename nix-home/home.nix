{ pkgs, ... }:

{

  # The home-manager manual is at:
  #
  #   https://rycee.gitlab.io/home-manager/release-notes.html
  #
  # Configuration options are documented at:
  #
  #   https://rycee.gitlab.io/home-manager/options.html

  # If you use non-standard XDG locations, set these options to the
  # appropriate paths:
  #
  # xdg.cacheHome
  # xdg.configHome
  # xdg.dataHome

  # Since we do not install home-manager, you need to let home-manager
  # manage your shell, otherwise it will not be able to add its hooks
  # to your profile.
  #programs.bash = {
  #  enable = true;
  #};
  # NOTE: Seems to be related to the loading of ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  # Grepping hm's src, this seems to be loaded when a shell is managed by hm
  # I'm not sure what 'hooks' the comment above is talking about though..
  # Looking at bash' & zsh' managed configs, I con't find any hooks, so simply loading that session vars file from my  # shell config should be enough!!!

  home.packages = [
    pkgs.bat
    pkgs.fd
    pkgs.htop
    pkgs.httpie
    pkgs.jq
    pkgs.just
    pkgs.ripgrep
    pkgs.tmux
    pkgs.tree
    pkgs.zsh

    pkgs.git
    pkgs.gitAndTools.delta

    # Nix tools
    pkgs.nix-tree # TUI to browse the dependencies of a derivation

    # media tools
    pkgs.mpv
  ];

  # FIXME: I'd like to be able to do:
  # home.files."some-symlink".link = "${sources.home-manager}";
  # Unfortunately, the home-manager module that manages files only supports 'text',
  # not 'link'.
  # Ultimately, all 'files' put in user's home will be symlinks (to the /nix/store),
  # but I'd like to make my own links too!
  # IDEA (or similar): what about making a dot.link."some-symlink".target = dot-path ./foo/bar;

  # FIXME: generated files linked in user's home are NOT modifiable!!
  # For my shell/neovim configs (at least), will need to see how to make a hackable env,
  # where all files would be modifiable in order to hack things!!!

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.09";
}
