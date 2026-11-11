# wrapkit's test entry point.
#
# Run with: `nix eval -f nix/kits/wrapkit/tests.nix`.
# Test names must start with `test` to be considered by `runTests`.

let
  flake = builtins.getFlake "pkgs";
  lib = flake.lib;
  pkgs = flake.legacyPackages.${builtins.currentSystem};

  module = import ./. { inherit pkgs lib; };
  wraplib = module.wraplib;

  # Fixtures: the hello binary, wrapped through each input shape.
  # Every `mkWrapkitBin` call returns `{ config; drv; }`.
  helloBin = "${pkgs.hello}/bin/hello";

  binDefaultName = wraplib.mkWrapkitBin {
    wrappedBin = helloBin;
    wrapper.env.FOO.set = "bar";
  };

  binExplicitName = wraplib.mkWrapkitBin {
    wrappedBin = helloBin;
    binName = "greet";
    wrapper.env.FOO.set = "bar";
  };

  binFromDerivation = wraplib.mkWrapkitBin {
    wrappedBin = pkgs.hello;
    wrapper.env.FOO.set = "bar";
  };

  # single-file layout: `binName = null` emits the executable file directly as `$out`.
  binSingleFile = wraplib.mkWrapkitBin {
    wrappedBin = helloBin;
    binName = null;
    wrapper.env.FOO.set = "bar";
  };

  # Inline-layering fixtures: a host holds the evaluated config and refines it
  # with `lib.extendWith`, exactly as the kit's extension helper allows.
  inlineBase = wraplib.mkWrapkitBin {
    wrappedBin = helloBin;
    wrapper.env.FOO.prepend = [ "/commons" ];
  };

  inlineScalarBase = wraplib.mkWrapkitBin {
    wrappedBin = helloBin;
    wrapper.env.FOO.set = "commons";
  };

  # Argument-assembly fixtures: resolve a partial record through the schema, so
  # every omitted field takes its null default, then assemble its `makeWrapper`
  # argument list.
  mkWrapperArgs = (import ./wrapper-model.nix { inherit lib; }).mkWrapperArgs;

  resolveWrapper = record:
    (lib.evalModules {
      modules = [
        { options.wrapper = lib.mkOption { type = wraplib.wrapperType; default = {}; }; }
        { wrapper = record; }
      ];
    }).config.wrapper;

  assembleArgs = record: mkWrapperArgs (resolveWrapper record);

  normalizeWrapper = (import ./wrapper-composer.nix { inherit lib; }).normalizeWrapper;

  # Layered builds: a host hands over resolved records, as it would with its
  # commons (`config.wrapper`) and a profile's override.
  layeredBin = wraplib.mkWrapkitBin {
    wrappedBin = helloBin;
    wrappers = [
      (resolveWrapper { env.FOO.prepend = [ "/commons" ]; env.BAR.set = "bar"; })
      (resolveWrapper { env.FOO.set = "override"; })
    ];
  };

  layeredListBin = wraplib.mkWrapkitBin {
    wrappedBin = helloBin;
    wrappers = [
      (resolveWrapper { env.FOO.prepend = [ "/a" ]; })
      (resolveWrapper { env.FOO.prepend = [ "/b" ]; })
    ];
  };

  tests = {
    "test.0default-binName" = {
      expr = lib.getExe binDefaultName.drv;
      expected = "${binDefaultName.drv}/bin/hello";
    };
    "test.1explicit-binName" = {
      expr = lib.getExe binExplicitName.drv;
      expected = "${binExplicitName.drv}/bin/greet";
    };
    "test.2derivation-target-name" = {
      expr = lib.getExe binFromDerivation.drv;
      expected = "${binFromDerivation.drv}/bin/hello";
    };
    "test.3output-is-derivation" = {
      expr = lib.isDerivation binDefaultName.drv;
      expected = true;
    };
    "test.4wrapper-option-path" = {
      expr = binDefaultName.config.wrapper.env.FOO.set;
      expected = "bar";
    };
    "test.5constructor-exported" = {
      expr = builtins.isFunction wraplib.mkWrapkitBin;
      expected = true;
    };
    "test.6wrapperType-exported" = {
      expr = builtins.isAttrs wraplib.wrapperType;
      expected = true;
    };

    # env actions, each mapping to its `makeWrapper` flag.
    "test.7env-set" = {
      expr = assembleArgs { env.FOO.set = "bar"; };
      expected = [ "--set" "FOO" "bar" ];
    };
    "test.8env-setDefault" = {
      expr = assembleArgs { env.FOO.setDefault = "bar"; };
      expected = [ "--set-default" "FOO" "bar" ];
    };
    "test.9env-unset" = {
      expr = assembleArgs { env.FOO.unset = true; };
      expected = [ "--unset" "FOO" ];
    };
    "test.10env-unset-false-noop" = {
      expr = assembleArgs { env.FOO.unset = false; };
      expected = [ ];
    };
    "test.11env-prepend-default-sep" = {
      expr = assembleArgs { env.FOO.prepend = [ "/a" "/b" ]; };
      expected = [ "--prefix" "FOO" ":" "/a:/b" ];
    };
    "test.12env-append-custom-sep" = {
      expr = assembleArgs { env.FOO.sep = "-"; env.FOO.append = [ "/a" "/b" ]; };
      expected = [ "--suffix" "FOO" "-" "/a-/b" ];
    };
    "test.13env-prependFromFile" = {
      expr = assembleArgs { env.FOO.prependFromFile = [ "/some/file" ]; };
      expected = [ "--prefix-contents" "FOO" ":" "/some/file" ];
    };
    "test.14env-appendFromFile" = {
      expr = assembleArgs { env.FOO.appendFromFile = [ "/some/file" ]; };
      expected = [ "--suffix-contents" "FOO" ":" "/some/file" ];
    };

    # argument ordering within and across VARs.
    "test.15env-scalar-before-prefix" = {
      expr = assembleArgs { env.FOO.set = "x"; env.FOO.prepend = [ "/a" ]; };
      expected = [ "--set" "FOO" "x" "--prefix" "FOO" ":" "/a" ];
    };
    "test.16env-unset-after-set" = {
      expr = assembleArgs { env.FOO.set = "x"; env.FOO.unset = true; };
      expected = [ "--set" "FOO" "x" "--unset" "FOO" ];
    };
    "test.17env-multi-var-alphabetical" = {
      expr = assembleArgs { env.B.set = "2"; env.A.set = "1"; };
      expected = [ "--set" "A" "1" "--set" "B" "2" ];
    };

    # invocation flags, one singular flag per element.
    "test.18flags-beforeArgs" = {
      expr = assembleArgs { flags.beforeArgs = [ "--config" "/x" ]; };
      expected = [ "--add-flag" "--config" "--add-flag" "/x" ];
    };
    "test.19flags-afterArgs" = {
      expr = assembleArgs { flags.afterArgs = [ "-d" ]; };
      expected = [ "--append-flag" "-d" ];
    };
    "test.20flags-beforeArgs-space-stays-one-arg" = {
      expr = assembleArgs { flags.beforeArgs = [ "with space" ]; };
      expected = [ "--add-flag" "with space" ];
    };

    # process control.
    "test.21argv0-inherit" = {
      expr = assembleArgs { argv0 = "inherit"; };
      expected = [ "--inherit-argv0" ];
    };
    "test.22argv0-resolve" = {
      expr = assembleArgs { argv0 = "resolve"; };
      expected = [ "--resolve-argv0" ];
    };
    "test.23argv0-name" = {
      expr = assembleArgs { argv0 = "myapp"; };
      expected = [ "--argv0" "myapp" ];
    };
    "test.24chdir" = {
      expr = assembleArgs { chdir = "/tmp"; };
      expected = [ "--chdir" "/tmp" ];
    };
    "test.25run" = {
      expr = assembleArgs { run = [ "echo hi" "echo bye" ]; };
      expected = [ "--run" "echo hi" "--run" "echo bye" ];
    };

    # `sep` validation: an invalid separator fails the kit eval's assertion.
    "test.26sep-empty-invalid" = {
      expr = (builtins.tryEval (wraplib.mkWrapkitBin {
        wrappedBin = helloBin;
        wrapper.env.FOO.sep = "";
        wrapper.env.FOO.prepend = [ "/a" ];
      }).drv.buildCommand).success;
      expected = false;
    };
    "test.27sep-multichar-invalid" = {
      expr = (builtins.tryEval (wraplib.mkWrapkitBin {
        wrappedBin = helloBin;
        wrapper.env.FOO.sep = "::";
        wrapper.env.FOO.prepend = [ "/a" ];
      }).drv.buildCommand).success;
      expected = false;
    };

    # mode selection: `wrapper` and `wrappers` are mutually exclusive, enforced
    # by an assertion in the kit eval.
    "test.28wrapper-and-wrappers-mutually-exclusive" = {
      expr = (builtins.tryEval (wraplib.mkWrapkitBin {
        wrappedBin = helloBin;
        wrapper.env.FOO.set = "inline";
        wrappers = [ (resolveWrapper { env.BAR.set = "layered"; }) ];
      }).drv.buildCommand).success;
      expected = false;
    };

    # layered mode: each record is normalised, then applied as one definition, so
    # an override that touches one action leaves the other actions for that VAR.
    "test.29layered-override-action" = {
      expr = lib.hasInfix "--set FOO override" layeredBin.drv.buildCommand;
      expected = true;
    };
    "test.30layered-commons-action-inherited" = {
      expr = lib.hasInfix "--prefix FOO : /commons" layeredBin.drv.buildCommand;
      expected = true;
    };
    "test.31layered-commons-var-inherited" = {
      expr = lib.hasInfix "--set BAR bar" layeredBin.drv.buildCommand;
      expected = true;
    };
    "test.32layered-list-order-follows-layer-order" = {
      expr = lib.hasInfix "--prefix FOO : /a:/b" layeredListBin.drv.buildCommand;
      expected = true;
    };
    "test.33layered-scalar-collision-fails" = {
      expr = (builtins.tryEval (wraplib.mkWrapkitBin {
        wrappedBin = helloBin;
        wrappers = [
          (resolveWrapper { env.FOO.set = "a"; })
          (resolveWrapper { env.FOO.set = "b"; })
        ];
      }).drv.buildCommand).success;
      expected = false;
    };

    # the normaliser strips absent fields, which is what keeps one layer from
    # defining the actions another layer left unset.
    "test.34normalizeWrapper-drops-absent-fields" = {
      expr = normalizeWrapper (resolveWrapper { env.FOO.set = null; });
      expected = { };
    };
    "test.35normalizeWrapper-keeps-set-actions" = {
      expr = normalizeWrapper (resolveWrapper { env.FOO.set = "x"; });
      expected = { env = { FOO = { set = "x"; }; }; };
    };

    # inline mode: the evaluated config is refined with `lib.extendWith`, using
    # ordinary module priority within one kit eval.
    "test.36inline-override-action" = {
      expr = (inlineBase.config.lib.extendWith ({ wrapper.env.FOO.set = "override"; })).wrapper.env.FOO.set;
      expected = "override";
    };
    "test.37inline-commons-action-inherited" = {
      expr = (inlineBase.config.lib.extendWith ({ wrapper.env.FOO.set = "override"; })).wrapper.env.FOO.prepend;
      expected = [ "/commons" ];
    };
    "test.38inline-collision-without-mkForce-fails" = {
      expr = (builtins.tryEval (inlineScalarBase.config.lib.extendWith ({ wrapper.env.FOO.set = "override"; })).wrapper.env.FOO.set).success;
      expected = false;
    };
    "test.39inline-mkForce-wins-collision" = {
      expr = (inlineScalarBase.config.lib.extendWith ({ wrapper.env.FOO.set = lib.mkForce "override"; })).wrapper.env.FOO.set;
      expected = "override";
    };

    # single-file layout: `binName = null` builds the executable as `$out`, with no `bin/`
    # directory and no `meta.mainProgram` (so `lib.getExe` does not resolve it).
    "test.40single-file-layout" = {
      expr = lib.hasInfix "$out/bin" binSingleFile.drv.buildCommand;
      expected = false;
    };
    "test.41single-file-no-mainProgram" = {
      expr = binSingleFile.drv.meta.mainProgram or null;
      expected = null;
    };
    "test.42bin-dir-layout" = {
      expr = lib.hasInfix "$out/bin/hello" binDefaultName.drv.buildCommand;
      expected = true;
    };
    "test.43single-file-derivation-name" = {
      expr = binSingleFile.drv.name;
      expected = "hello-wrapped-bin";
    };

    # install helper: `mkWrapkitWrapperOption` yields a wrapper-record option a
    # host can mount at any name.
    "test.44wrapper-option-helper" = {
      expr = (lib.evalModules {
        modules = [
          { options.wrapper = wraplib.mkWrapkitWrapperOption { }; }
          { wrapper.env.FOO.set = "bar"; }
        ];
      }).config.wrapper.env.FOO.set;
      expected = "bar";
    };
    "test.45wrapper-option-helper-nested-name" = {
      expr = (lib.evalModules {
        modules = [
          { options.profiles.foo.cfg = wraplib.mkWrapkitWrapperOption { }; }
          { profiles.foo.cfg.env.FOO.set = "bar"; }
        ];
      }).config.profiles.foo.cfg.env.FOO.set;
      expected = "bar";
    };
    "test.46wrapper-option-helper-exported" = {
      expr = builtins.isFunction wraplib.mkWrapkitWrapperOption;
      expected = true;
    };

    # --- M7: the kit half ---
    # `mkWrapkitBin` returns the evaluated config and the wrapped derivation.
    "test.47mkWrapkitBin-shape" = {
      expr = builtins.attrNames binDefaultName;
      expected = [ "config" "drv" ];
    };
    # the evaluated config comes from a kitsys eval: it carries `lib.extendWith`
    # and the kit's nesting state.
    "test.48config-carries-extendWith" = {
      expr = builtins.isFunction binDefaultName.config.lib.extendWith;
      expected = true;
    };
    "test.49config-nesting-level" = {
      expr = binDefaultName.config._kitState.nestingLevel;
      expected = 0;
    };
    # `lib.extendWith` re-evaluates the config, so the refined derivation picks
    # up the layered definition.
    "test.50extendWith-refines-drv" = {
      expr = lib.hasInfix "--set FOO refined"
        (inlineBase.config.lib.extendWith ({ wrapper.env.FOO.set = "refined"; })).output.buildCommand;
      expected = true;
    };
    # the public entry point exposes only the helper library.
    "test.51entrypoint-exports-wraplib-only" = {
      expr = builtins.attrNames module;
      expected = [ "wraplib" ];
    };
    "test.52wraplib-helpers" = {
      expr = builtins.attrNames wraplib;
      expected = [ "mkWrapkitBin" "mkWrapkitWrapperOption" "wrapperType" ];
    };
  };

  nicer_testResults = let
    testResults = lib.runTests tests;
    fmtTestNames = lib.concatStringsSep ", " (builtins.attrNames tests);
  in (
    if testResults == []
    then "Tests successful ✨ (${fmtTestNames})"
    else testResults
  );
in
  nicer_testResults
