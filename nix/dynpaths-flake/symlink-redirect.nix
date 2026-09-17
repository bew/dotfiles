{ lib, runCommandLocal }:


# Configuration:
{
  # Root name, exposed for diagnostics (checker messages)
  name,
  # Store-side base of the root, stripped from the given path
  nixStorePath,
  # Real path on the system, will be used as the base for symlink redirects
  realPath,
}:

# Returns a linker function that is configured to replace `nixStorePath` by `realPath` in `givenPath`
givenPath:

let
  # Strip the store prefix from given path (if any) so that:
  # given `givenPath`: ./foo
  # with param `nixStorePath`: /nix/store/aaaaaaa-the-flake-source
  # with param `realPath`: "/realPath"
  # then `(toString givenPath)`: "/nix/store/aaaaaaa-the-flake-source/path/to/foo"
  # then `directLinkPath`: "/realPath/path/to/foo"
  directLinkPath = toString realPath + lib.removePrefix (toString nixStorePath) (toString givenPath);
in

# $out is a drv that create a symlink redirect:
# .. from store path ($out) -> to live target (like ~/.dot/foo)
runCommandLocal "direct-symlink-${builtins.baseNameOf givenPath}" {
  # Expose the real redirect target so callers can inspect it during eval.
  # (e.g. to gen activation checks)
  passthru.dynpathRedirectTarget = directLinkPath;
  # Expose the winning Root so callers can report it (e.g. checker messages).
  passthru.dynpathMatchedRoot = { inherit name nixStorePath realPath; };
} ''
  # NOTE: We cannot verify that the source path exists here.
  # This builder runs in the Nix sandbox, and `givenPath` (a store path) is not
  # declared as a derivation input, so the sandbox denies access to it.
  # Path existence is checked at activation time via dynpaths.checkedPaths.
  ln -s ${lib.escapeShellArg directLinkPath} $out
''
