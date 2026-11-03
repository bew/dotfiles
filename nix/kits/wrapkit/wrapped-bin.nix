# Resolve a wrap target to an executable path and a command name.
#
# A wrap target is either a path string (`"${pkg}/bin/foo"`) or a derivation.
# A derivation is resolved with `lib.getExe`, which requires `meta.mainProgram`.
# Without it the command name cannot be derived, so the caller must pass an
# explicit `binName` together with a path-string target.

{ lib, ... }:

rec {
  # The executable path of a wrap target: the path string as-is, or the
  # `meta.mainProgram` binary of a derivation.
  resolveWrappedBin = wrappedBin:
    if lib.isDerivation wrappedBin then lib.getExe wrappedBin else wrappedBin;

  # The command name of the resolved binary, used as the default `binName`.
  defaultBinName = wrappedBin: baseNameOf (resolveWrappedBin wrappedBin);
}
