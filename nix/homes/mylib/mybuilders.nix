{pkgs, lib, ...}:

rec {
  # Creates a derivation with only links to the given binaries.
  # The binaries to include are described by a spec, see the examples below.
  #
  # Can be used:
  # * to rename binaries
  # * to rename binaries to allow multiple version of the same software
  #   in the same environment
  # * to expose only a few binaries of a derivation
  #
  # NOTE: Using linkBins, the packages used to define the new binaries can't install their normal
  # outputs, thus 'man' output is never available... Similarly shell completions, icons, libs,
  # includes, configs are not included.
  # This builder is ONLY useful to make binaries available.
  # => Use `replaceBinsInPkg` to replace bins in an existing package while keeping its structure.
  #
  # Types:
  #   linkBins :: { name :: String; ... } -> derivation
  #   linkBins :: [ String or { name :: String; path :: String; } ] -> derivation
  #
  # Examples:
  #   (linkBins "my-bins1" [
  #     pkgs.neovim
  #     "/tmp/foo/bar"
  #   ])
  #   => creates a derivation like:
  #     /nix/store/znk3qkb30ccgq6kvgmv69jj4ci9bin18-my-bins1/
  #     └── bin/
  #         ├── nvim -> /nix/store/frlxim9yz5qx34ap3iaf55caawgdqkip-neovim-0.5.1/bin/nvim
  #         └── bar -> /tmp/foo/bar
  #
  #   (linkBins "my-bins2" [
  #     {name = "nvim-stable"; path = pkgs.neovim;}
  #     "/tmp/foo/bar"
  #   ])
  #   => creates a derivation like:
  #     /nix/store/f35182nny6lb95srh0lbxfd5hq99kr8s-my-bins2/
  #     └── bin/
  #         ├── nvim-stable -> /nix/store/frlxim9yz5qx34ap3iaf55caawgdqkip-neovim-0.5.1/bin/nvim
  #         └── bar -> /tmp/foo/bar
  #
  #   (linkBins "my-bins3" {
  #     nvim-stable = pkgs.neovim;
  #     bar-tmp = "/tmp/foo/bar";
  #   })
  #   => creates a derivation like:
  #     /nix/store/3v6mk91b4n4758zli921y2z27xm3a5v2-my-bins3/
  #     └── bin/
  #         ├── nvim-stable -> /nix/store/frlxim9yz5qx34ap3iaf55caawgdqkip-neovim-0.5.1/bin/nvim
  #         └── bar-tmp -> /tmp/foo/bar
  #
  # TODO: allow to pass `mainProgram = true;` in a spec
  # => set a bin as the `meta.mainProgram` of the resulting drv
  linkBins = name: binsSpec:
    let
      binSpecHelp = ''
        a binSpec can be either:
        - a string: "/path/to/foo"
        - a set pointing to a string: { name = "foo"; path = "/path/to/foo"; }
        - a derivation: pkgs.neovim
        - a set pointing to a derivation: { name = "nvim-custom"; path = pkgs.neovim; }
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
          let binTarget = item.path; in {
            inherit (item) name;
            path = (
              if (typeOf binTarget) == "string" then
                binTarget
              else if (typeOf binTarget) == "set" && (binTarget ? outPath) then
                lib.getExe binTarget
              else
                throw ''
                  For linkBins: Unable to find target bin path '${name}' of type '${typeOf binTarget}'
                  ${binsSpecHelp}
                ''
            );
          }
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
  #     └── bin/
  #         └── nvim -> /nix/store/frlxim9yz5qx34ap3iaf55caawgdqkip-neovim-0.5.1/bin/nvim
  #
  linkSingleBin = path:
    let
      binName = baseNameOf path;
      meta.mainProgram = binName;
    in pkgs.runCommandLocal "${binName}-single-bin" { inherit meta; } ''
      mkdir -p $out/bin
      ln -s ${lib.escapeShellArg path} $out/bin/
    '';

  # Copy full package, remove existing bin/ and replace with the given list of bins.
  #
  # This is useful to patch some binaries / force them to use some
  # configuration, while preserving the pkg layout, allowing `man tool` to
  # auto-find the manpage of the tool when it's installed in home.packages!
  #
  # Example:
  #   replaceBinsInPkg {
  #     name = "custom-fzf";
  #     copyFromPkg = fzf;
  #     bins = {
  #       fzf = writeShellScript "fzf" ''
  #         exec ${fzf}/bin/fzf --custom-args right here --and=here "$@"
  #       '';
  #     };
  #     postBuild = "
  #   }
  #   => creates a derivation like:
  #     /nix/store/xx3yknpx0yvnks0dqvsd11n7p1zm5mb4-custom-fzf
  #     ├── bin
  #     │   └── fzf
  #     └── share
  #         ├── fish -> /nix/store/3fz694nbl7ndyinz7xmhz77inzn0a17h-fzf-0.35.1/share/fish
  #         ├── fzf -> /nix/store/3fz694nbl7ndyinz7xmhz77inzn0a17h-fzf-0.35.1/share/fzf
  #         ├── man -> /nix/store/5fl47ah7k40j6pk0ln74wf3kby2h8jp1-fzf-0.35.1-man/share/man
  #         └── vim-plugins -> /nix/store/3fz694nbl7ndyinz7xmhz77inzn0a17h-fzf-0.35.1/share/vim-plugins
  #
  #   replaceBinsInPkg {
  #     name = "custom-zsh";
  #     copyFromPkg = zsh;
  #     nativeBuildInputs = [ makeWrapper ];
  #     postBuild = /* sh */ ''
  #       makeWrapper ${zsh}/bin/zsh $out/bin/zsh --set ZDOTDIR /some/new/zdotdir
  #     '';
  #   };
  #   => creates a derivation like:
  #     /nix/store/p85wi35yda68xw9xr2s1lamgv4hqh1jl-custom-zsh
  #     ├── bin
  #     │   └── zsh
  #     ├── etc -> /nix/store/dy11j8bd6a6gq0nsgx54zddg32qrcd7l-zsh-5.8.1/etc
  #     ├── lib -> /nix/store/dy11j8bd6a6gq0nsgx54zddg32qrcd7l-zsh-5.8.1/lib
  #     └── share -> /nix/store/dy11j8bd6a6gq0nsgx54zddg32qrcd7l-zsh-5.8.1/share
  #
  replaceBinsInPkg = { name, copyFromPkg, bins ? {}, nativeBuildInputs ? [], postBuild ? "", meta ? {} }:
    pkgs.buildEnv {
      inherit name nativeBuildInputs meta;
      paths = [ copyFromPkg ];
      postBuild = /* sh */ ''
        if [[ -e $out/bin ]]; then
          echo "Remove existing bin/ (was: `readlink $out/bin`)"
          # No need for '-r', it's a symlink!
          rm -f $out/bin
        fi
        echo "Create empty bin/"
        mkdir $out/bin

        ${lib.optionalString (0 != (lib.length (lib.attrNames bins))) ''
          echo "Add binaries: ${lib.concatStringsSep ", " (lib.attrNames bins)}"
          ${lib.concatStringsSep "\n"
            (lib.mapAttrsToList
              (name: targetBin: "cp ${toString targetBin} $out/bin/${name}")
              bins
            )
          }
        ''}

        ${lib.optionalString (0 != (lib.stringLength postBuild)) ''
          echo "Run postBuild to add more binaries"
          ${postBuild}
        ''}
      '';
    };
}
