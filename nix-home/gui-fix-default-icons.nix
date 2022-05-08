{ config, pkgsChannels, ... }:

let
  inherit (pkgsChannels) stable;
in {
  home.packages = [
    # hicolor-icon-theme contains the standard icons for freedesktop.
    # Ref: https://www.freedesktop.org/wiki/Software/icon-theme/
    stable.hicolor-icon-theme

    # adwaita-icon-theme contains the standard icons for Gnome / GTK apps.
    stable.gnome.adwaita-icon-theme

    # breeze-icons is a freedesktop compatible icon theme. It’s developed by the KDE Community
    # as part of KDE Frameworks 5 and it’s used by default in KDE Plasma 5 and KDE Applications.
    # Ref: https://develop.kde.org/frameworks/breeze-icons/
    stable.breeze-icons
  ];

  # Tell home-manager to fill XDG_DATA_DIRS var with the user's nix profile /share
  # directory, where all icons & icon themes are.
  #
  # NOTE: the X session should source `<profile>/etc/profile.d/hm-session-vars.sh`
  # on start to get this variable
  #
  # NOTE: 'config.home.profileDirectory' <=> '~/.nix-profile'
  xdg.systemDirs.data = [ "${config.home.profileDirectory}/share" ];
}
