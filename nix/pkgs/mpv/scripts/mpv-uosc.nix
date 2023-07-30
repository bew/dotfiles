{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
}:

stdenvNoCC.mkDerivation rec {
  pname = "mpv-uosc";
  version = "4.7.0";

  src = fetchFromGitHub {
    owner = "tomasklaen";
    repo = "uosc";
    rev = version;
    hash = "sha256-JqlBjhwRgmXl6XfHYTwtNWZj656EDHjcdWOlCgihF5I=";
  };

  dontBuild = true;
  installPhase = ''
    mkdir -p $out/share/mpv/
    cp -r scripts $out/share/mpv/
    cp -r fonts $out/share/mpv/
  '';
  passthru.scriptName = "uosc.lua";

  meta = with lib; {
    description = "Feature-rich minimalist proximity-based UI for MPV player.";
    homepage = "https://github.com/tomasklaen/uosc";
    license = licenses.gpl3;
    platforms = platforms.all;
    maintainers = with maintainers; [ bew ];
  };
}
