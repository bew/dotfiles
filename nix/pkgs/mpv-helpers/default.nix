{
  runCommandLocal,
  lib,

  jo,
  socat,
  mpv,
  jq,
}:

runCommandLocal "@mpv" {} /* sh */ ''
  mkdir -p $out/bin
  substitute ${./mpv-helpers.sh} $out/bin/@mpv \
    --replace "_BIN_mpv=" "_BIN_mpv=${lib.getExe mpv} #" \
    --replace "_BIN_socat=" "_BIN_socat=${lib.getExe socat} #" \
    --replace "_BIN_jq=" "_BIN_jq=${lib.getExe jq} #" \
    --replace "_BIN_jo=" "_BIN_jo=${lib.getExe jo} #"
  chmod +x $out/bin/@mpv
''
