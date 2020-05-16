let
  nixpkgs = import <nixpkgs> {};
  inherit (nixpkgs) stdenv pkgs;

  # drv for the ZDOTDIR with the config file

  # FIXME: maybe there is a simpler pkgs.* builder tool to do this...
  zdotdir = stdenv.mkDerivation rec {
    name = "zdotdir";

    # srcs = ./minimal_zshrc; # 'srcs' is a file / list of files/(dir?)
    # src = srcs; # 'src' must be a directory if

    src = ./minimal_zshrc;

    # If this is what is used to determine the input of this derivation, it means I cannot use it in this case, since it'll see the change to default.nix (which is in this directory) and determine that it needs a new derivation, even if default.nix is not used FOR the derivation?
    # I could also ignore the nix files in ./. ?
    # What _really_ happens when I set `src = ./.` ? does it compute the hash of ALL files recursively and use it as an input for the final hash? (that would make sense)

    phases = "installPhase";

    # # FIXME: here ./minimal_zshrc is directly copied to /nix/store and used here,
    # # can this be done another way?
    # installPhase = ''
    #   mkdir -p $out
    #   cp ${./minimal_zshrc} $out/.zshrc
    # '';

    installPhase = ''
      mkdir -p $out
      cp $src $out/.zshrc
    '';
  };

  # drv for the zsh wrapper that points to a custom ZDOTDIR
  minimal-zsh = pkgs.runCommand "minimal-zsh" { buildInputs = [ pkgs.makeWrapper ]; }
    ''
      makeWrapper ${pkgs.zsh}/bin/zsh $out \
        --set ZDOTDIR "${zdotdir}" #--set TERM linux
    '';

in minimal-zsh
