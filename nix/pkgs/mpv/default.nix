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

      # UI
      (callPackage ./scripts/mpv-modernx.nix {})

      # (callPackage ./scripts/mpv-uosc.nix {})
      # note: uosc can do many things, but is a little bloated, and doesn't show actual playlist..
      #   proximity and slight animations aren't my thing
    ];
  };

in
  mybuilders.replaceBinsInPkg {
    name = "mpv-bew";
    copyFromPkg = mpv-unwrapped;
    nativeBuildInputs = [ makeWrapper ];
    # Setup the binary to point to the config dir, and disable default OSC.
    postBuild = /* sh */ ''
      makeWrapper ${lib.getExe mpv-unwrapped} $out/bin/mpv \
        --set MPV_HOME ${mpv-config-dir}/share/mpv \
        --add-flags '--no-osc'
    '';
    meta.mainProgram = "mpv";
  }
