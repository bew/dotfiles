{
  lib,
  ...
}:

# Ref: https://wiki.archlinux.org/title/Locale#My_system_is_still_using_wrong_language
let
  kdePlasmaLocalrcFilepath = "$HOME/.config/plasma-localerc";
in
{
  home.activation.ensureSystemLocales = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [[ -f ${kdePlasmaLocalrcFilepath} ]]; then
      echo "Ensure KDE plasma doesn't setup locales (use system settings)"
      rm -vf ${kdePlasmaLocalrcFilepath}
    fi
  '';
}
