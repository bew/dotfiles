# The base module loaded first into every wrapkit kit eval.
#
# Declares the `wrapper` record option and the read-only `output` derivation,
# and validates the wrapper's per-VAR `sep` through the eval's assertions.
# `mkWrapkitBin` injects `wrappedBin` and `binName` through `_module.args`; the
# kit eval provides `pkgs` and `lib`.

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

  # `sep` only matters where a prefix/suffix action is emitted, so validate it
  # only there. `makeWrapper` expands the separator through the shell's IFS, so
  # it must be exactly one character long.
  sepAssertions = lib.mapAttrsToList (var: actions:
    let
      sep = if actions.sep == null then ":" else actions.sep;
      usesSep =
        actions.prepend != null
        || actions.append != null
        || (actions.prependFromFile != null && actions.prependFromFile != [ ])
        || (actions.appendFromFile != null && actions.appendFromFile != [ ]);
    in {
      assertion = !usesSep || lib.stringLength sep == 1;
      message = "wrapkit: env.${var}.sep must be a non-empty single character, got `${sep}`.";
    }) config.wrapper.env;
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

  # The kit eval reports one assertion per VAR whose `sep` is used but invalid.
  config.assertions = sepAssertions;
}
