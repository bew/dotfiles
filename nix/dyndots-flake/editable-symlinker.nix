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

# $out is a drv that create a symlink redirect:
# .. from store path ($out) -> to editable target (like ~/.dot/foo)
runCommandLocal "direct-symlink-${builtins.baseNameOf givenPath}" {
  # Expose the real redirect target so callers can inspect it during eval.
  # (e.g. to gen activation checks)
  passthru.dyndotsRedirectTarget = directLinkPath;
} ''
  # NOTE: We cannot verify that the source path exists here.
  # This builder runs in the Nix sandbox, and `givenPath` (a store path) is not
  # declared as a derivation input, so the sandbox denies access to it.
  # Path existence is checked at activation time via dyndots.checkedPaths.
  ln -s ${lib.escapeShellArg directLinkPath} $out
''
