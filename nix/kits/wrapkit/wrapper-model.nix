# The wrap model: the wrap target, and the wrapper-record schema and its
# lowering to `makeWrapper` argv.
#
# A wrap target is resolved to an executable path and a command name.
# `wrapperType` models the full `makeWrapper` surface: every env action with a
# per-VAR `sep`, the wrapped invocation's flags, and the wrapped process's own
# control. `mkWrapperArgs` turns a resolved record of that shape into the
# argument list `makeWrapper` consumes.

{ lib, ... }:

let
  ty = lib.types;

  # A wrap target is either a path string (`"${pkg}/bin/foo"`) or a derivation.
  # A derivation is resolved with `lib.getExe`, which requires
  # `meta.mainProgram`. Without it the command name cannot be derived, so the
  # caller must pass an explicit `binName` together with a path-string target.
  resolveWrappedBin = wrappedBin:
    if lib.isDerivation wrappedBin then lib.getExe wrappedBin else wrappedBin;

  # The command name of the resolved binary, used as the default `binName`.
  defaultBinName = wrappedBin: baseNameOf (resolveWrappedBin wrappedBin);

  # The actions of one environment variable, in `makeWrapper` vocabulary.
  # Every field defaults to `null`: under module priority a default is a
  # definition, so a non-null default would collide with a layered record.
  envVarType = ty.submodule {
    options = {
      sep = lib.mkOption {
        description = "Separator joining the prepend/append variants; null applies the emitter's `:`.";
        type = ty.nullOr ty.str;
        default = null;
      };
      set = lib.mkOption {
        description = "Value emitted as `--set <VAR> <value>`; null emits no flag.";
        type = ty.nullOr ty.str;
        default = null;
      };
      setDefault = lib.mkOption {
        description = "Value emitted as `--set-default <VAR> <value>`; null emits no flag.";
        type = ty.nullOr ty.str;
        default = null;
      };
      unset = lib.mkOption {
        description = "When true, emit `--unset <VAR>`; null and false emit no flag.";
        type = ty.nullOr ty.bool;
        default = null;
      };
      prepend = lib.mkOption {
        description = "Values joined by `sep` and emitted as one `--prefix <VAR> <sep> <value>`.";
        type = ty.nullOr (ty.listOf ty.str);
        default = null;
      };
      append = lib.mkOption {
        description = "Values joined by `sep` and emitted as one `--suffix <VAR> <sep> <value>`.";
        type = ty.nullOr (ty.listOf ty.str);
        default = null;
      };
      prependFromFile = lib.mkOption {
        description = "Files emitted as one `--prefix-contents <VAR> <sep> <file>` each.";
        type = ty.nullOr (ty.listOf ty.path);
        default = null;
      };
      appendFromFile = lib.mkOption {
        description = "Files emitted as one `--suffix-contents <VAR> <sep> <file>` each.";
        type = ty.nullOr (ty.listOf ty.path);
        default = null;
      };
    };
  };

  # `makeWrapper` emits shell operations in argument order, so the assembly
  # orders each VAR's scalar family (`setDefault`, `set`, `unset`) before its
  # prefix/suffix family, and joins each list into a single `--prefix`/`--suffix`
  # rather than repeating the flag.

  # `null` means "no flag"; an empty list still emits its flag.
  asList = maybeList: if maybeList == null then [] else maybeList;

  # One VAR's arguments: scalars first, so `unset` has the last word, then the
  # prefix/suffix family, which writes the variable.
  mkEnvVarArgs = var: actions:
    let
      sep = if actions.sep == null then ":" else actions.sep;

      joinValues = values: lib.concatStringsSep sep values;

      scalarArgs =
        lib.optionals (actions.setDefault != null) [ "--set-default" var actions.setDefault ]
        ++ lib.optionals (actions.set != null) [ "--set" var actions.set ]
        ++ lib.optionals (actions.unset == true) [ "--unset" var ];

      prefixSuffixArgs =
        lib.optionals (actions.prepend != null) [ "--prefix" var sep (joinValues actions.prepend) ]
        ++ lib.optionals (actions.append != null) [ "--suffix" var sep (joinValues actions.append) ]
        ++ lib.concatMap (file: [ "--prefix-contents" var sep (toString file) ]) (asList actions.prependFromFile)
        ++ lib.concatMap (file: [ "--suffix-contents" var sep (toString file) ]) (asList actions.appendFromFile);
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
  inherit resolveWrappedBin defaultBinName;

  # The schema of one wrapper's whole surface: env actions, invocation flags, and process control.
  wrapperType = ty.submodule {
    options = {
      env = lib.mkOption {
        description = "Environment variables to apply to the wrapped binary, keyed by variable name.";
        type = ty.attrsOf envVarType;
        default = {};
      };

      flags = lib.mkOption {
        description = "Arguments passed to the wrapped program itself.";
        type = ty.submodule {
          options = {
            beforeArgs = lib.mkOption {
              description = "Values emitted as one `--add-flag` each, before the wrapped program's own arguments.";
              type = ty.nullOr (ty.listOf ty.str);
              default = null;
            };
            afterArgs = lib.mkOption {
              description = "Values emitted as one `--append-flag` each, after the wrapped program's own arguments.";
              type = ty.nullOr (ty.listOf ty.str);
              default = null;
            };
          };
        };
        default = {};
      };

      argv0 = lib.mkOption {
        description = "`null` emits no flag, `inherit`/`resolve` select the matching flag, any other string emits `--argv0 <value>`.";
        type = ty.nullOr (ty.either (ty.enum [ "inherit" "resolve" ]) ty.str);
        default = null;
      };

      chdir = lib.mkOption {
        description = "Directory emitted as `--chdir <dir>`; null emits no flag.";
        type = ty.nullOr ty.str;
        default = null;
      };

      run = lib.mkOption {
        description = "Commands emitted as one `--run <command>` each; null emits no flag.";
        type = ty.nullOr (ty.listOf ty.str);
        default = null;
      };
    };
  };

  # Assemble the full `makeWrapper` argument list for a resolved wrapper record.
  mkWrapperArgs = wrapper:
    lib.concatLists (lib.mapAttrsToList mkEnvVarArgs wrapper.env)
    ++ mkFlagsArgs wrapper.flags
    ++ mkProcessArgs wrapper;
}
