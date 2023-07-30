{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
}:

stdenvNoCC.mkDerivation rec {
  pname = "mpv-undoredo";
  version = "2.2.1";

  # NOTE: https://github.com/Eisa01/mpv-scripts
  # has a number of other small scripts.
  src = fetchFromGitHub {
    owner = "Eisa01";
    repo = "mpv-scripts";
    rev = version;
    hash = "sha256-jzwIvfnBCtCfgDGDvgV3ywohlJdx2eDPb5ZmodOmuSw=";
  };

  dontBuild = true;
  installPhase = ''
    install -D -t $out/share/mpv/scripts scripts/UndoRedo.lua
  '';
  passthru.scriptName = "UndoRedo.lua";

  meta = with lib; {
    description = "Mpv script to undo/redo any accident time jumps in the video (Ctrl-z/Ctrl-y)";
    homepage = "https://github.com/Eisa01/mpv-scripts#undoredo";
    license = licenses.bsd2;
    platforms = platforms.all;
    maintainers = with maintainers; [ bew ];
  };
}
