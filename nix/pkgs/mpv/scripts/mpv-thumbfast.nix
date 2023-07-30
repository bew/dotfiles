{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
}:

stdenvNoCC.mkDerivation rec {
  pname = "mpv-thumbfast";
  version = "unstable-2023-07-30";

  # NOTE: https://github.com/Eisa01/mpv-scripts
  # has a number of other small scripts.
  src = fetchFromGitHub {
    owner = "po5";
    repo = "thumbfast";
    rev = "4241c7daa444d3859b51b65a39d30e922adb87e9";
    hash = "sha256-7EnFJVjEzqhWXAvhzURoOp/kad6WzwyidWxug6u8lVw=";
  };

  dontBuild = true;
  installPhase = ''
    install -D -t $out/share/mpv/scripts thumbfast.lua
  '';
  passthru.scriptName = "thumbfast.lua";

  meta = with lib; {
    description = "High-performance on-the-fly thumbnailer script for mpv";
    homepage = "https://github.com/po5/thumbfast";
    license = licenses.bsd2;
    platforms = platforms.all;
    maintainers = with maintainers; [ bew ];
  };
}
