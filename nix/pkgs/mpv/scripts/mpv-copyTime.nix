{
  stdenvNoCC,
  fetchFromGitHub,
  lib,

  # depenencies
  xclip,
}:

stdenvNoCC.mkDerivation rec {
  pname = "mpv-copyTime";
  version = "unstable-2023-07-30";

  src = fetchFromGitHub {
    owner = "Arieleg";
    repo = "mpv-copyTime";
    rev = "10b53d507085ba2deda301b6fab3397eee275b71";
    hash = "sha256-7yYwHTpNo4UAaQdMVF5n//Hnk8+O+x1Q5MXG6rfFNpc=";
  };

  patches = [ ./mpv-copyTime-xclip.patch ];

  postPatch = ''
    substituteInPlace copyTime.lua \
      --replace 'return "xclip' \
                'return "${lib.getExe xclip}'
  '';

  dontBuild = true;
  installPhase = ''
    install -D -t $out/share/mpv/scripts copyTime.lua
  '';
  passthru.scriptName = "copyTime.lua";

  meta = with lib; {
    description = "Mpv script to copy the current time of the video to clipboard.";
    homepage = "https://github.com/Arieleg/mpv-copyTime";
    license = licenses.gpl3;
    platforms = platforms.all;
    maintainers = with maintainers; [ bew ];
  };
}
