# The wrapper record schema, shared by the base module and wrapkit's public
# exports.
#
# Models the full `makeWrapper` surface: every env action with a per-VAR `sep`,
# the wrapped invocation's flags, and the wrapped process's own control.

{ lib, ... }:

let
  ty = lib.types;

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
in {
  # The schema of one wrapper's whole surface: env actions, invocation flags,
  # and process control.
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
}
