# wrapkit's test entry point.
#
# Run with: `nix eval -f nix/wrapkit/tests.nix`.
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

  baseEval = lib.evalModules {
    modules = [
      ./wrapkit-base.module.nix
      { wrapper.env.FOO.set = "bar"; }
    ];
    specialArgs = { inherit pkgs; wrappedBin = helloBin; binName = "hello"; };
  };

  # Argument-assembly fixtures: resolve a partial record through the schema, so
  # every omitted field takes its null default, then assemble its `makeWrapper`
  # argument list.
  mkWrapperArgs = (import ./wrapper-args.nix { inherit lib; }).mkWrapperArgs;

  resolveWrapper = record:
    (lib.evalModules {
      modules = [
        { options.wrapper = lib.mkOption { type = wrapkit.wrapperType; default = {}; }; }
        { wrapper = record; }
      ];
    }).config.wrapper;

  assembleArgs = record: mkWrapperArgs (resolveWrapper record);

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
