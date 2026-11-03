# Assemble the `makeWrapper` argument list from a wrapper record.
#
# `makeWrapper` emits shell operations in argument order, so the assembly orders
# each VAR's scalar family (`setDefault`, `set`, `unset`) before its
# prefix/suffix family, and joins each list into a single `--prefix`/`--suffix`
# rather than repeating the flag.

{ lib, ... }:

let
  # `null` means "no flag"; an empty list still emits its flag.
  asList = maybeList: if maybeList == null then [] else maybeList;

  # One VAR's arguments: scalars first, so `unset` has the last word, then the
  # prefix/suffix family, which writes the variable.
  mkEnvVarArgs = var: actions:
    let
      sep = if actions.sep == null then ":" else actions.sep;

      # `makeWrapper` expands the separator through the shell's IFS, so it must
      # be exactly one character long.
      checkSep = args:
        if lib.stringLength sep == 1
        then args
        else throw "wrapkit: env.${var}.sep must be a non-empty single character, got `${sep}`.";

      joinValues = values: lib.concatStringsSep sep values;

      scalarArgs =
        lib.optionals (actions.setDefault != null) [ "--set-default" var actions.setDefault ]
        ++ lib.optionals (actions.set != null) [ "--set" var actions.set ]
        ++ lib.optionals (actions.unset == true) [ "--unset" var ];

      prefixSuffixArgs =
        lib.optionals (actions.prepend != null) (checkSep [ "--prefix" var sep (joinValues actions.prepend) ])
        ++ lib.optionals (actions.append != null) (checkSep [ "--suffix" var sep (joinValues actions.append) ])
        ++ lib.concatMap (file: checkSep [ "--prefix-contents" var sep (toString file) ]) (asList actions.prependFromFile)
        ++ lib.concatMap (file: checkSep [ "--suffix-contents" var sep (toString file) ]) (asList actions.appendFromFile);
    in
    scalarArgs ++ prefixSuffixArgs;

  mkFlagsArgs = flags:
    lib.concatMap (arg: [ "--add-flag" arg ]) (asList flags.beforeArgs)
    ++ lib.concatMap (arg: [ "--append-flag" arg ]) (asList flags.afterArgs);

  mkProcessArgs = wrapper:
    lib.optionals (wrapper.argv0 == "inherit") [ "--inherit-argv0" ]
    ++ lib.optionals (wrapper.argv0 == "resolve") [ "--resolve-argv0" ]
    ++ lib.optionals (wrapper.argv0 != null && wrapper.argv0 != "inherit" && wrapper.argv0 != "resolve") [ "--argv0" wrapper.argv0 ]
    ++ lib.optionals (wrapper.chdir != null) [ "--chdir" wrapper.chdir ]
    ++ lib.concatMap (command: [ "--run" command ]) (asList wrapper.run);
in {
  # Assemble the full `makeWrapper` argument list for a resolved wrapper record.
  mkWrapperArgs = wrapper:
    lib.concatLists (lib.mapAttrsToList mkEnvVarArgs wrapper.env)
    ++ mkFlagsArgs wrapper.flags
    ++ mkProcessArgs wrapper;
}
