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

  kitsys = import ../../kit-system { inherit lib; };

  # The kit itself: one kitsys evaluation over the base module. Every
  # `mkWrapkitBin` call runs this kit, layering that wrap's inline records on
  # top of it.
  wrapkit = kitsys.newKit ({ self, kitsys }: {
    meta.name = "Wrapkit system";
    baseModules = [ ./wrapkit-base.module.nix ];
    eval = kitsys.defineEval { inherit self; class = "wrapkit"; };
  });

  # Run the wrapkit kit over the caller's wrapper input and return the evaluated
  # config together with the wrapped derivation (`config.output`).
  #
  # wrappedBin — the binary to wrap: a path string, or a derivation resolved with `lib.getExe`.
  # binName — the command name; defaults to the resolved binary's command name.
  #   A string selects the `$out/bin/<binName>` layout; null selects the
  #   single-file `$out` layout.
  # wrapper — one record written as definitions (inline mode); null loads no record.
  # wrappers — resolved records applied in order (layered mode); null loads no record.
  # specialArgs — extra values threaded into the kit eval as module args.
  #
  # The two record inputs are mutually exclusive; passing both fails the eval's
  # assertion.
  mkWrapkitBin = {
    wrappedBin,
    binName ? defaultBinName wrappedBin,
    wrapper ? null,
    wrappers ? null,
    specialArgs ? {},
  }:
    let
      bothGiven = wrapper != null && wrappers != null;

      # An inline record enters the kit eval untouched, so merging stays
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

      evaluated = wrapkit.eval {
        inherit pkgs lib;
        config = { _module.args = { inherit wrappedBin binName; } // specialArgs; };
        moreModules =
          map (record: { wrapper = record; }) recordDefinitions
          ++ [ {
            assertions = [ {
              assertion = !bothGiven;
              message = "wrapkit: `wrapper` and `wrappers` are mutually exclusive.";
            } ];
          } ];
      };
    in
    {
      config = evaluated;
      drv = evaluated.output;
    };
in {
  wraplib = {
    inherit mkWrapkitBin wrapperType mkWrapkitWrapperOption;
  };
}
