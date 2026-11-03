# wrapkit's test entry point.
#
# Run with: `nix eval -f nix/kits/wrapkit/tests.nix`.
# Test names must start with `test` to be considered by `runTests`.

let
  flake = builtins.getFlake "pkgs";
  lib = flake.lib;
  pkgs = flake.legacyPackages.${builtins.currentSystem};

  wrapkit = import ./. { inherit pkgs lib; };

  # Fixtures: the hello binary, wrapped through each input shape.
  helloBin = "${pkgs.hello}/bin/hello";

  binDefaultName = wrapkit.mkWrapkitBin {
    wrappedBin = helloBin;
    wrapper.env.FOO.set = "bar";
  };

  binExplicitName = wrapkit.mkWrapkitBin {
    wrappedBin = helloBin;
    binName = "greet";
    wrapper.env.FOO.set = "bar";
  };

  binFromDerivation = wrapkit.mkWrapkitBin {
    wrappedBin = pkgs.hello;
    wrapper.env.FOO.set = "bar";
  };

  # single-file layout: `binName = null` emits the executable file directly as `$out`.
  binSingleFile = wrapkit.mkWrapkitBin {
    wrappedBin = helloBin;
    binName = null;
    wrapper.env.FOO.set = "bar";
  };

  # Resolve the effective wrapper from definitions written directly against the
  # base module, as inline mode's own evaluation does.
  inlineEval = modules:
    lib.evalModules {
      modules = [ ./wrapkit-base.module.nix ] ++ modules;
      specialArgs = { inherit pkgs; wrappedBin = helloBin; binName = "hello"; };
    };

  baseEval = inlineEval [ { wrapper.env.FOO.set = "bar"; } ];

  # Argument-assembly fixtures: resolve a partial record through the schema, so
  # every omitted field takes its null default, then assemble its `makeWrapper`
  # argument list.
  mkWrapperArgs = (import ./wrapper-model.nix { inherit lib; }).mkWrapperArgs;

  resolveWrapper = record:
    (lib.evalModules {
      modules = [
        { options.wrapper = lib.mkOption { type = wrapkit.wrapperType; default = {}; }; }
        { wrapper = record; }
      ];
    }).config.wrapper;

  assembleArgs = record: mkWrapperArgs (resolveWrapper record);

  normalizeWrapper = (import ./wrapper-composer.nix { inherit lib; }).normalizeWrapper;

  # Layered builds: a host hands over resolved records, as it would with its
  # commons (`config.wrapper`) and a profile's override.
  layeredBin = wrapkit.mkWrapkitBin {
    wrappedBin = helloBin;
    wrappers = [
      (resolveWrapper { env.FOO.prepend = [ "/commons" ]; env.BAR.set = "bar"; })
      (resolveWrapper { env.FOO.set = "override"; })
    ];
  };

  layeredListBin = wrapkit.mkWrapkitBin {
    wrappedBin = helloBin;
    wrappers = [
      (resolveWrapper { env.FOO.prepend = [ "/a" ]; })
      (resolveWrapper { env.FOO.prepend = [ "/b" ]; })
    ];
  };

  tests = {
    "test.0default-binName" = {
      expr = lib.getExe binDefaultName;
      expected = "${binDefaultName}/bin/hello";
    };
    "test.1explicit-binName" = {
      expr = lib.getExe binExplicitName;
      expected = "${binExplicitName}/bin/greet";
    };
    "test.2derivation-target-name" = {
      expr = lib.getExe binFromDerivation;
      expected = "${binFromDerivation}/bin/hello";
    };
    "test.3output-is-derivation" = {
      expr = lib.isDerivation binDefaultName;
      expected = true;
    };
    "test.4wrapper-option-path" = {
      expr = baseEval.config.wrapper.env.FOO.set;
      expected = "bar";
    };
    "test.5constructor-exported" = {
      expr = builtins.isFunction wrapkit.mkWrapkitBin;
      expected = true;
    };
    "test.6wrapperType-exported" = {
      expr = builtins.isAttrs wrapkit.wrapperType;
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

    # `sep` validation.
    "test.26sep-empty-invalid" = {
      expr = (builtins.tryEval (assembleArgs { env.FOO.sep = ""; env.FOO.prepend = [ "/a" ]; })).success;
      expected = false;
    };
    "test.27sep-multichar-invalid" = {
      expr = (builtins.tryEval (assembleArgs { env.FOO.sep = "::"; env.FOO.prepend = [ "/a" ]; })).success;
      expected = false;
    };

    # mode selection.
    "test.28wrapper-and-wrappers-mutually-exclusive" = {
      expr = (builtins.tryEval (wrapkit.mkWrapkitBin {
        wrappedBin = helloBin;
        wrapper.env.FOO.set = "inline";
        wrappers = [ (resolveWrapper { env.BAR.set = "layered"; }) ];
      }).buildCommand).success;
      expected = false;
    };

    # layered mode: each record is normalised, then applied as one definition, so
    # an override that touches one action leaves the other actions for that VAR.
    "test.29layered-override-action" = {
      expr = lib.hasInfix "--set FOO override" layeredBin.buildCommand;
      expected = true;
    };
    "test.30layered-commons-action-inherited" = {
      expr = lib.hasInfix "--prefix FOO : /commons" layeredBin.buildCommand;
      expected = true;
    };
    "test.31layered-commons-var-inherited" = {
      expr = lib.hasInfix "--set BAR bar" layeredBin.buildCommand;
      expected = true;
    };
    "test.32layered-list-order-follows-layer-order" = {
      expr = lib.hasInfix "--prefix FOO : /a:/b" layeredListBin.buildCommand;
      expected = true;
    };
    "test.33layered-scalar-collision-fails" = {
      expr = (builtins.tryEval (wrapkit.mkWrapkitBin {
        wrappedBin = helloBin;
        wrappers = [
          (resolveWrapper { env.FOO.set = "a"; })
          (resolveWrapper { env.FOO.set = "b"; })
        ];
      }).buildCommand).success;
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

    # inline mode: ordinary module priority within one module application.
    "test.36inline-override-action" = {
      expr = (inlineEval [
        { wrapper.env.FOO.prepend = [ "/commons" ]; }
        { wrapper.env.FOO.set = "override"; }
      ]).config.wrapper.env.FOO.set;
      expected = "override";
    };
    "test.37inline-commons-action-inherited" = {
      expr = (inlineEval [
        { wrapper.env.FOO.prepend = [ "/commons" ]; }
        { wrapper.env.FOO.set = "override"; }
      ]).config.wrapper.env.FOO.prepend;
      expected = [ "/commons" ];
    };
    "test.38inline-collision-without-mkForce-fails" = {
      expr = (builtins.tryEval (inlineEval [
        { wrapper.env.FOO.set = "commons"; }
        { wrapper.env.FOO.set = "override"; }
      ]).config.wrapper.env.FOO.set).success;
      expected = false;
    };
    "test.39inline-mkForce-wins-collision" = {
      expr = (inlineEval [
        { wrapper.env.FOO.set = "commons"; }
        { wrapper.env.FOO.set = lib.mkForce "override"; }
      ]).config.wrapper.env.FOO.set;
      expected = "override";
    };

    # single-file layout: `binName = null` builds the executable as `$out`, with no `bin/`
    # directory and no `meta.mainProgram` (so `lib.getExe` does not resolve it).
    "test.40single-file-layout" = {
      expr = lib.hasInfix "$out/bin" binSingleFile.buildCommand;
      expected = false;
    };
    "test.41single-file-no-mainProgram" = {
      expr = binSingleFile.meta.mainProgram or null;
      expected = null;
    };
    "test.42bin-dir-layout" = {
      expr = lib.hasInfix "$out/bin/hello" binDefaultName.buildCommand;
      expected = true;
    };
    "test.43single-file-derivation-name" = {
      expr = binSingleFile.name;
      expected = "hello-wrapped-bin";
    };

    # install helper: `mkWrapkitWrapperOption` yields a wrapper-record option a
    # host can mount at any name.
    "test.44wrapper-option-helper" = {
      expr = (lib.evalModules {
        modules = [
          { options.wrapper = wrapkit.mkWrapkitWrapperOption { }; }
          { wrapper.env.FOO.set = "bar"; }
        ];
      }).config.wrapper.env.FOO.set;
      expected = "bar";
    };
    "test.45wrapper-option-helper-nested-name" = {
      expr = (lib.evalModules {
        modules = [
          { options.profiles.foo.cfg = wrapkit.mkWrapkitWrapperOption { }; }
          { profiles.foo.cfg.env.FOO.set = "bar"; }
        ];
      }).config.profiles.foo.cfg.env.FOO.set;
      expected = "bar";
    };
    "test.46wrapper-option-helper-exported" = {
      expr = builtins.isFunction wrapkit.mkWrapkitWrapperOption;
      expected = true;
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
