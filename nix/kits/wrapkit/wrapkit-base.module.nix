# The base module loaded first into every wrapkit mini-eval.
#
# Declares the `wrapper` record option and the read-only `output` derivation.
# `mkWrapkitBin` injects `pkgs`, `wrappedBin`, and `binName` through the eval's
# `specialArgs`.

{ config, lib, pkgs, wrappedBin, binName, ... }:

let
  ty = lib.types;

  wrapperType = (import ./wrapper-schema.nix { inherit lib; }).wrapperType;
  resolveWrappedBin = (import ./wrapped-bin.nix { inherit lib; }).resolveWrappedBin;
  mkWrapperArgs = (import ./wrapper-args.nix { inherit lib; }).mkWrapperArgs;

  resolvedWrappedBin = resolveWrappedBin wrappedBin;

  # Assemble the `makeWrapper` argument list from the effective wrapper record.
  wrapperArgs = mkWrapperArgs config.wrapper;
in {
  options = {
    wrapper = lib.mkOption {
      description = "The wrapper record applied to the wrapped binary.";
      type = wrapperType;
      default = {};
    };

    output = lib.mkOption {
      description = "The wrapped binary derivation, at `$out/bin/<binName>` (Layout 2).";
      type = ty.package;
      readOnly = true;
    };
  };

  config.output = pkgs.runCommandLocal binName {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta.mainProgram = binName;
  } ''
    mkdir -p $out/bin
    makeWrapper ${lib.escapeShellArg resolvedWrappedBin} $out/bin/${binName} ${lib.escapeShellArgs wrapperArgs}
  '';
}
