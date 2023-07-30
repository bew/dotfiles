{
  mpv-unwrapped,
  makeWrapper,

  callPackage,
  buildEnv,

  pkgs, lib,
}:

# NOTE: The builtin wrapper `mpv.override` basically only allows to set `--script=...` repeatedly,
# but does not support other configurations like input, font, options..

let
  # FIXME: there must be a better way to pass 'mybuilders' down to here than manually import it..
  mybuilders = import ./../../homes/mylib/mybuilders.nix { inherit pkgs lib; };

  # ref: https://mpv.io/manual/stable/#files
  mpv-config-dir = buildEnv {
    name = "mpv-bew-config-dir";
    pathsToLink = [ "/share/mpv" ];
    paths = [
      (callPackage ./scripts/mpv-undoredo.nix {})
      (callPackage ./scripts/mpv-thumbfast.nix {})
      (callPackage ./scripts/mpv-copyTime.nix {})
      (callPackage ./scripts/mpv-uosc.nix {})
    ];
  };

in
  mybuilders.replaceBinsInPkg {
    name = "mpv-bew";
    copyFromPkg = mpv-unwrapped;
    nativeBuildInputs = [ makeWrapper ];
    postBuild = /* sh */ ''
      makeWrapper ${mpv-unwrapped}/bin/mpv $out/bin/mpv --set MPV_HOME ${mpv-config-dir}/share/mpv
    '';
  }
