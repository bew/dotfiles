# wrapkit's public constructors.
#
# `mkWrapkitBin` wraps one binary from an inline `wrapper` record; `wrapperType`
# is the schema of that record.

{ pkgs, lib, ... }:

let
  wrapperType = (import ./wrapper-schema.nix { inherit lib; }).wrapperType;
  defaultBinName = (import ./wrapped-bin.nix { inherit lib; }).defaultBinName;

  # Run a mini-eval over the base module plus the caller's wrapper record and
  # return the wrapped binary.
  #
  # wrappedBin — the binary to wrap: a path string, or a derivation resolved with `lib.getExe`.
  # binName — the command name; defaults to the resolved binary's command name.
  # wrapper — one record written as definitions (inline mode); null loads no record.
  # specialArgs — extra values threaded into the mini-eval.
  mkWrapkitBin = {
    wrappedBin,
    binName ? defaultBinName wrappedBin,
    wrapper ? null,
    specialArgs ? {},
  }:
    let
      records = lib.optional (wrapper != null) wrapper;
    in
    (lib.evalModules {
      modules = [ ./wrapkit-base.module.nix ] ++ map (record: { wrapper = record; }) records;
      specialArgs = { inherit pkgs wrappedBin binName; } // specialArgs;
    }).config.output;
in {
  inherit mkWrapkitBin wrapperType;
}
