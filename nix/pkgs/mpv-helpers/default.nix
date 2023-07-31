{
  runCommandLocal,

  jo,
  socat,
  mpv,
  jq,
}:

runCommandLocal "@mpv" {} /* sh */ ''
  mkdir -p $out/bin
  substitute ${./mpv-helpers.sh} $out/bin/@mpv \
    --replace "_BIN_mpv=" "_BIN_mpv=${mpv}/bin/mpv #" \
    --replace "_BIN_socat=" "_BIN_socat=${socat}/bin/socat #" \
    --replace "_BIN_jq=" "_BIN_jq=${jq}/bin/jq #" \
    --replace "_BIN_jo=" "_BIN_jo=${jo}/bin/jo #"
  chmod +x $out/bin/@mpv
''
