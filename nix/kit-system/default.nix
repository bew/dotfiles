{ lib }:

let
  MAX_NESTING_LEVEL = 1000;

  # A module that declares the _required_ `lib` option (needed for defining nested eval below)
  declareLibOptionModule = {lib, ...}: let ty = lib.types; in {
    options.lib = lib.mkOption {
      description = "Set of lib functions to help write configs";
      type = ty.attrsOf (ty.uniq ty.anything);
    };
  };

  mkHigherPriority = prevEvalLevel: content: (
    let
      higherPriority = MAX_NESTING_LEVEL - prevEvalLevel - 1;
    in lib.mkOverride higherPriority content
  );

  # Returns a module defining the nested eval function.
  # 👉 Allows to take a full config and refine it later if needed.
  mkModuleForNestedEval = { self, prevEvalParams, prevEval, ... }: {
    # Extend current config with the given module.
    config.lib.extendWith = module: (
      let
        evaluated = prevEval.extendModules {
          modules = [ module ];
        };
      in evaluated.config
    );

    # Same as lib.extendWith, supports accessing prevConfig
    config.lib.extendWithPrevConfig = configMoreOverride: self.eval {
      inherit (prevEvalParams) pkgs lib config configOverride;
      moreModules = prevEvalParams.moreModules ++ [
        configMoreOverride
        # Also allow the new config to access the previous config :P
        {
          # NOTE: We need to set a higher priority (lower number is higher priority) here,
          # to make sure that 2+ nesting evals won't have conflicting `superConfig` definitions,
          # and the current one has access to the _previous_ config.
          _module.args.prevConfig = mkHigherPriority prevEvalParams._nestedEvalLevel prevEval.config;
        }
      ];
      _nestedEvalLevel = prevEvalParams._nestedEvalLevel + 1;
    };
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
  }: (
    {
      pkgs,
      lib ? pkgs.lib,
      config,
      # FIXME: configOverride still useful since we have lib.extendWith?
      configOverride ? {},
      moreModules ? [],
      _nestedEvalLevel ? 1,
      ...
    }@givenEvalParams:
    let
      # note: cannot solely use `{..}@evalParams` above because it doesn't auto-fill defaults.
      #   See in repl: `({ a, b ? "default"}@params: params) { a = 1; }`
      #   .. which gives `{ a=1; }` instead of `{ a=1; b="default"; }`
      # So we take what was explicitely given, and inject the optionals to make sure they are set.
      allEvalParams = givenEvalParams // {
        inherit lib configOverride moreModules _nestedEvalLevel;
      };

      evaluated = lib.evalModules {
        inherit class;
        specialArgs = { inherit pkgs; } // extraSpecialArgs;
        modules = self.baseModules ++ [ config configOverride ] ++ moreModules ++ [
          (if declareLibOption then declareLibOptionModule else {})
          (mkModuleForNestedEval {
            inherit self;
            prevEvalParams = allEvalParams;
            prevConfig = evaluated.config;
            prevEval = evaluated;
          })
        ];
      };
    in evaluated.config
  );
})
