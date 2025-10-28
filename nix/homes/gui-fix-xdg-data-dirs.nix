{ config, pkgsChannels, ... }:

let
  inherit (pkgsChannels) stable;
in {
  home.packages = [
    # hicolor-icon-theme contains the standard icons for freedesktop.
    # Ref: https://www.freedesktop.org/wiki/Software/icon-theme/
    stable.hicolor-icon-theme

    # adwaita-icon-theme contains the standard icons for Gnome / GTK apps.
    stable.adwaita-icon-theme

    # breeze-icons is a freedesktop compatible icon theme. It’s developed by the KDE Community
    # as part of KDE Frameworks and it’s used by default in KDE Plasma and KDE Applications.
    # REF: https://develop.kde.org/frameworks/breeze-icons/
    stable.kdePackages.breeze-icons
  ];

  # Tell home-manager to set XDG_DATA_DIRS var with the user's nix profile /share
  # directory, where e.g: all icons & icon themes are. (in addition to standard-Linux system/user dirs)
  #
  # NOTE: the X session should source `<profile>/etc/profile.d/hm-session-vars.sh`
  # on start to get this variable
  xdg.systemDirs.data = [
    # NOTE: 'config.home.profileDirectory' <=> '~/.nix-profile'
    "${config.home.profileDirectory}/share"

    # Also load standard-Linux system/user xdg data directories
    "${config.home.homeDirectory}/.local/share"
    "/usr/share"
    "/usr/local/share"

    # And finally load NixOS' global data directories
    "/run/current-system/sw/share"
  ];
}
