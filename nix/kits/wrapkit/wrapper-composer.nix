# How wrapper records combine: normalise a resolved record for layered
# application, and expose the record as a reusable option.
#
# A resolved record carries every field, the unset ones as `null`. Applied raw
# it would define fields its author never touched, at normal priority, colliding
# with every other layer that touches them. Stripping the absent fields leaves
# exactly the actions the record sets, so the layers merge per action.

{ lib, ... }:

let
  wrapperType = (import ./wrapper-model.nix { inherit lib; }).wrapperType;

  # Drop `null` fields, and the sets that dropping them empties, so an absent
  # field becomes no definition rather than a value.
  dropAbsent = lib.filterAttrs (_: value: value != null && value != {});

  # `unset = false` spells "no flag" in the schema, so it drops with the nulls;
  # only a literal `true` survives.
  keepEnvField = field: value: field != "unset" || value == true;
  normalizeEnvVar = actions: dropAbsent (lib.filterAttrs keepEnvField actions);
in {
  normalizeWrapper = record: dropAbsent {
    env = lib.filterAttrs (_: actions: actions != {}) (lib.mapAttrs (_: normalizeEnvVar) record.env);
    flags = dropAbsent record.flags;
    argv0 = record.argv0;
    chdir = record.chdir;
    run = record.run;
  };

  # The `wrapper` record as a reusable option, so a host declares one under any
  # name, at any site (e.g. `options.profiles.foo.cfg`), from the same schema
  # the base module's own `wrapper` option uses.
  mkWrapkitWrapperOption = { }:
    lib.mkOption {
      description = "A wrapper record applied to a wrapped binary.";
      type = wrapperType;
      default = {};
    };
}
