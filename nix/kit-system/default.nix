{ lib }:

let
  # Impl copied from the very recent `lib.asserts.checkAssertWarn` (@2025-05)
  checkAssertWarn = with lib;
    assertions: warnings: val:
    let
      failedAssertions = map (x: x.message) (filter (x: !x.assertion) assertions);
    in
    if failedAssertions != [ ] then
      throw "\nFailed assertions:\n${concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
    else
      showWarnings warnings val;

  checkAssertsAndWarnings = config: (
    # Check assertions & warnings: (returns the evaluated config if all good)
    # - show all warnings
    # - fail with messages for all false asserts
    checkAssertWarn
      config.assertions
      config.warnings
      config
  );

  # A module that declares the _required_ `lib` option (needed for defining nested eval below)
  declareLibOptionModule = {lib, ...}: let ty = lib.types; in {
    options.lib = lib.mkOption {
      description = "Set of lib functions to help write configs";
      type = ty.attrsOf (ty.uniq ty.anything);
    };
  };

  # Interesting related work, to follow:
  # - Reusable assertions (aka, integrate them in the module system)
  #   <https://github.com/NixOS/nixpkgs/pull/207187>
  # - structured attrs for warnings/assertions
  #   <https://github.com/NixOS/nixpkgs/pull/342372>
  declareAssertWarnOptionsModule = {lib, ...}: let ty = lib.types; in {
    options.assertions = lib.mkOption {
      description = "List of assertions to check";
      type = ty.listOf (ty.submodule {
        options = {
          assertion = lib.mkOption {
            type = ty.bool;
            description = "Assertion condition that must be true";
          };
          message = lib.mkOption {
            type = ty.str;
            description = "Error message to display when assertion fails";
          };
        };
      });
      default = [];
    };

    options.warnings = lib.mkOption {
      description = "List of warning messages to display";
      type = ty.listOf ty.str;
      default = [];
    };
  };

  # A module defining the `config.lib.extendWith` function for multi-level config extension ✨
  # 👉 Allows to take a full kit-based config and refine it later as needed.
  declareConfigExtensionHelperModule = {lib, config, ...}: {
    options._kitState = let ty = lib.types; in {
      # Not strictly necessary, but can be useful information.
      nestingLevel = lib.mkOption {
        description = "Nesting level of the current kitsys eval, overridden with each config extension";
        type = ty.ints.unsigned;
        default = 0;
      };
      # NOTE: This is needed to be able to access current eval in the impl of `lib.extendWith`
      currentEval = lib.mkOption {
        type = ty.raw; # zero smart, zero merging
        # note: initial value is set in `kit.eval` with the option-default's priority
      };
    };

    # Extend current config with the given module.
    # Supports accessing `prevConfig` in module args if needed.
    config.lib.extendWith = module: (
      let
        prev_kitState = config._kitState;
        prevEval = prev_kitState.currentEval;
        # NOTE: We need to set a higher priority (less is more) for options here, to make sure
        # that 2+ nesting evals won't have conflicting option definitions when overriding value.
        higherPrio = prevEval.options._kitState.nestingLevel.highestPrio - 1;

        evaluated = prevEval.extendModules {
          modules = [
            module
            {
              _kitState.nestingLevel = lib.mkOverride higherPrio (prev_kitState.nestingLevel + 1);
              # NOTE: Storing the eval in the config is necessary to be able to retrieve highestPrio of an
              # option in prevEval.
              #
              # note: Due to Nix's lazyness its value should never actually be evaluated until I actually
              # need a config value from a prev config
              _kitState.currentEval = lib.mkOverride higherPrio evaluated;

              # Expose the previous config if an extension module needs the before-extension value
              # of something.
              _module.args.prevConfig = lib.mkOverride higherPrio prevEval.config;
            }
          ];
        };
      in checkAssertsAndWarnings evaluated.config
    );
  };

in lib.fix (kitsys: {
  newKit = kitDef: lib.fix (self: kitDef { inherit self kitsys; });

  defineEval = {
    # The current kit definition, can be used to access extra fields
    self,
    # Module class
    class ? null,
    # Extra arguments passed to specialArgs.
    extraSpecialArgs ? {},

    # Set to `false` if `lib` option is already defined in `self.baseModules` to avoid conflicting
    # definitions.
    declareLibOption ? true,

    # Set to `false` if `assertions`/`warnings` options are already defined in `self.baseModules` to
    # avoid conflicting definitions.
    declareAssertWarnOptions ? true,
  }: (
    let
      kitsysBaseModules = [
        (if declareLibOption then declareLibOptionModule else {})
        (if declareAssertWarnOptions then declareAssertWarnOptionsModule else {})
        declareConfigExtensionHelperModule
      ];
    in {
      pkgs,
      lib ? pkgs.lib,
      config,
      # FIXME: configOverride still useful since we have lib.extendWith?
      configOverride ? {},
      moreModules ? [],
      ...
    }:
    let
      evaluated = lib.evalModules {
        inherit class;
        specialArgs = { inherit pkgs; } // extraSpecialArgs;
        modules = (
          kitsysBaseModules
          ++ self.baseModules
          ++ [ config configOverride ]
          ++ moreModules
          ++ [
            # Initialize the state with the current eval, using option-default priority to ensure
            # all _kitState options have the same priority.
            { _kitState.currentEval = lib.mkOptionDefault evaluated; }
          ]
        );
      };
    in checkAssertsAndWarnings evaluated.config
  );
})
