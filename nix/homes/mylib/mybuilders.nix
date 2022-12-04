{pkgs, lib, ...}:

rec {
  # Creates a derivation with only links to the given binaries.
  # The binaries to include are described by a spec, see the examples below.
  #
  # Can be used:
  # * to rename binaries
  # * to rename binaries to allow multiple version of the same software
  #   in the same derivation or the same top-level environment (which is also a derivation).
  # * to expose only a few binaries of a derivation.
  #
  # Types:
  #   linkBins :: { name :: String; ... } -> derivation
  #   linkBins :: [ String or { name :: String; path :: String; } ] -> derivation
  #
  # Examples:
  #   (linkBins "my-bins1" [
  #     "${pkgs.neovim}/bin/nvim"
  #     "/tmp/foo/bar"
  #   ])
  #   => creates a derivation like:
  #     /nix/store/znk3qkb30ccgq6kvgmv69jj4ci9bin18-my-bins1/
  #     `-- bin/
  #         |-- nvim -> /nix/store/frlxim9yz5qx34ap3iaf55caawgdqkip-neovim-0.5.1/bin/nvim
  #         `-- bar -> /tmp/foo/bar
  #
  #   (linkBins "my-bins2" [
  #     {name = "nvim-stable"; path = "${pkgs.neovim}/bin/nvim";}
  #     "/tmp/foo/bar"
  #   ])
  #   => creates a derivation like:
  #     /nix/store/f35182nny6lb95srh0lbxfd5hq99kr8s-my-bins2/
  #     `-- bin/
  #         |-- nvim-stable -> /nix/store/frlxim9yz5qx34ap3iaf55caawgdqkip-neovim-0.5.1/bin/nvim
  #         `-- bar -> /tmp/foo/bar
  #
  #   (linkBins "my-bins3" {
  #     nvim-stable = "${pkgs.neovim}/bin/nvim";
  #     bar-tmp = "/tmp/foo/bar";
  #   })
  #   => creates a derivation like:
  #     /nix/store/3v6mk91b4n4758zli921y2z27xm3a5v2-my-bins3/
  #     `-- bin/
  #         |-- nvim-stable -> /nix/store/frlxim9yz5qx34ap3iaf55caawgdqkip-neovim-0.5.1/bin/nvim
  #         `-- bar-tmp -> /tmp/foo/bar
  #
  linkBins = name: binsSpec:
    let
      binSpecHelp = ''
        a binSpec can be either:
        - a string: "/path/to/foo"
        - a set: { name = "foo"; path = "/path/to/foo"; }
      '';
      binsSpecHelp = ''
        binsSpec argument can be either:
        - a list of binSpec: (see below)
        - a set: { foo = "/path/to/foo"; }

        ${binSpecHelp}
      '';

      typeOf = builtins.typeOf;
      binsSpecList =
        if (typeOf binsSpec) == "list" then binsSpec
        else if (typeOf binsSpec) == "set" then
          lib.mapAttrsToList (name: path: { inherit name path; }) binsSpec
        else
          throw ''
            For linkBins: Unable to normalize given binsSpec argument of type '${typeOf binsSpec}'
            ${binsSpecHelp}
          '';
      normalizedBinsSpec = lib.forEach binsSpecList (item:
        if (typeOf item) == "string" then
          { name = baseNameOf item; path = item; }
        else if (typeOf item) == "set" && (item ? "name") && (item ? "path") then
          item
        else
          throw ''
            For linkBins: Unable to normalize bin spec of type '${typeOf item}'
            ${binSpecHelp}
          ''
      );

    in pkgs.runCommandLocal name {} ''
      mkdir -p $out/bin
      cd $out/bin
      ${lib.concatMapStrings ({name, path}: ''
        ln -s ${lib.escapeShellArg path} ${lib.escapeShellArg name}
      '') normalizedBinsSpec}
    '';

  # Creates a derivation with a single link in bin/ to the given binary path.
  #
  # Type: linkSingleBin :: String -> derivation
  #
  # Example:
  #   linkSingleBin "${pkgs.neovim}/bin/nvim"
  #   => creates a derivation like:
  #     /nix/store/yv5aigjy8l9bi9kpqh7y1dzf6nv07cl0-nvim-single-bin/
  #     `-- bin/
  #         `-- nvim -> /nix/store/frlxim9yz5qx34ap3iaf55caawgdqkip-neovim-0.5.1/bin/nvim
  #
  linkSingleBin = path:
    pkgs.runCommandLocal "${baseNameOf path}-single-bin" { } ''
      mkdir -p $out/bin
      ln -s ${lib.escapeShellArg path} $out/bin/
    '';
}