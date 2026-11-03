# The base module loaded first into every wrapkit mini-eval.
#
# Declares the `wrapper` record option and the read-only `output` derivation.
# `mkWrapkitBin` injects `pkgs`, `wrappedBin`, and `binName` through the eval's
# `specialArgs`.

{ config, lib, pkgs, wrappedBin, binName, ... }:

let
  ty = lib.types;

  mkWrapkitWrapperOption = (import ./wrapper-composer.nix { inherit lib; }).mkWrapkitWrapperOption;
  resolveWrappedBin = (import ./wrapper-model.nix { inherit lib; }).resolveWrappedBin;
  mkWrapperArgs = (import ./wrapper-model.nix { inherit lib; }).mkWrapperArgs;

  resolvedWrappedBin = resolveWrappedBin wrappedBin;

  # The command name of the wrapped binary, used as the single-file derivation
  # name (the bin-dir layout uses `binName` instead).
  wrappedBinName = baseNameOf resolvedWrappedBin;

  # Assemble the `makeWrapper` argument list from the effective wrapper record.
  wrapperArgs = mkWrapperArgs config.wrapper;
in {
  options = {
    wrapper = mkWrapkitWrapperOption { };

    output = lib.mkOption {
      description = "The wrapped binary derivation: `$out/bin/<binName>` (bin-dir layout), or the executable file at `$out` when `binName` is null (single-file layout).";
      type = ty.package;
      readOnly = true;
    };
  };

  # bin-dir layout keeps `binName` as the command name and resolves via `lib.getExe`;
  # single-file layout emits the executable file directly as `$out`.
  config.output =
    if binName == null
    then pkgs.runCommandLocal "${wrappedBinName}-wrapped-bin" {
      nativeBuildInputs = [ pkgs.makeWrapper ];
    } ''
      makeWrapper ${lib.escapeShellArg resolvedWrappedBin} $out ${lib.escapeShellArgs wrapperArgs}
    ''
    else pkgs.runCommandLocal binName {
      nativeBuildInputs = [ pkgs.makeWrapper ];
      meta.mainProgram = binName;
    } ''
      mkdir -p $out/bin
      makeWrapper ${lib.escapeShellArg resolvedWrappedBin} $out/bin/${binName} ${lib.escapeShellArgs wrapperArgs}
    '';
}
