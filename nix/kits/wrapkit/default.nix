# wrapkit's public constructors.
#
# `mkWrapkitBin` wraps one binary from an inline `wrapper` record, or from an
# ordered list of resolved `wrappers`; `wrapperType` is the schema of that record.

{ pkgs, lib, ... }:

let
  wrapperType = (import ./wrapper-model.nix { inherit lib; }).wrapperType;
  defaultBinName = (import ./wrapper-model.nix { inherit lib; }).defaultBinName;
  normalizeWrapper = (import ./wrapper-composer.nix { inherit lib; }).normalizeWrapper;
  mkWrapkitWrapperOption = (import ./wrapper-composer.nix { inherit lib; }).mkWrapkitWrapperOption;

  # Run a mini-eval over the base module plus the caller's wrapper input and
  # return the wrapped binary.
  #
  # wrappedBin — the binary to wrap: a path string, or a derivation resolved with `lib.getExe`.
  # binName — the command name; defaults to the resolved binary's command name.
  #   A string selects the `$out/bin/<binName>` layout; null selects the
  #   single-file `$out` layout.
  # wrapper — one record written as definitions (inline mode); null loads no record.
  # wrappers — resolved records applied in order (layered mode); null loads no record.
  # specialArgs — extra values threaded into the mini-eval.
  #
  # The two record inputs are mutually exclusive; passing both is an error.
  mkWrapkitBin = {
    wrappedBin,
    binName ? defaultBinName wrappedBin,
    wrapper ? null,
    wrappers ? null,
    specialArgs ? {},
  }:
    let
      bothGiven = wrapper != null && wrappers != null;

      # An inline record enters the mini-eval untouched, so merging stays
      # ordinary module priority.
      # Layered values carry no priority, so each is normalised first, then
      # applied as one definition apiece.
      # They go last-to-first because the module system concatenates list-valued
      # definitions with the latest definition first, which would otherwise
      # reverse the accumulated entries against the layer order.
      recordDefinitions =
        if wrappers == null
        then lib.optional (wrapper != null) wrapper
        else map normalizeWrapper (lib.reverseList wrappers);
    in
    if bothGiven
    then throw "wrapkit: `wrapper` and `wrappers` are mutually exclusive."
    else (lib.evalModules {
      modules = [ ./wrapkit-base.module.nix ] ++ map (record: { wrapper = record; }) recordDefinitions;
      specialArgs = { inherit pkgs wrappedBin binName; } // specialArgs;
    }).config.output;
in {
  inherit mkWrapkitBin wrapperType mkWrapkitWrapperOption;
}
