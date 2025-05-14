{ lib, runCommandLocal }:


# Configuration:
{
  # Real path on the system, will be used as the base for editable links
  realPath,
  # Nix path to replace with real path
  nixStorePath,
}:

# Returns a linker function that is configured to replace `nixStorePath` by `realPath` in `givenPath`
givenPath:

let
  # Remove store prefix from given path (if any) so that:
  # given `givenPath`: ./foo
  # with param `realPath`: "/realPath"
  # with param `nixStorePath`: /nix/store/aaaaaaa-the-flake-source
  # then `(toString givenPath)`: "/nix/store/aaaaaaa-the-flake-source/path/to/foo"
  # then `directLinkPath`: "/realPath/path/to/foo"
  directLinkPath = lib.replaceStrings [(toString nixStorePath)] [(toString realPath)] (toString givenPath);
in

runCommandLocal "direct-symlink-${builtins.baseNameOf givenPath}" {} ''
  ln -s ${lib.escapeShellArg directLinkPath} $out
''
