let
  pkgs = builtins.getFlake "pkgs";
  lib = pkgs.lib;

  kitsys = import ./. { inherit lib; };

  minikit = kitsys.newKit (import ./test-kit/kit.nix);

  configInit = minikit.eval {
    inherit pkgs;
    config = {
      val = "first-value";
    };
  };

  configNested = configInit.lib.extendWith ({lib, ...}: {
    val = lib.mkForce "second-value, prev not used";
  });

  configNestedAgain = configNested.lib.extendWith ({lib, prevConfig, ...}: {
    val = lib.mkOverride 45 "third-value (was ${prevConfig.val})";
    # note: mkForce has priority 50, 45 has more priority
  });

  configWithWarn = configNestedAgain.lib.extendWith ({lib, ...}: {
    warnings = [ "test warning is working" ];
  });

  evals = {
    inherit configInit configNested configNestedAgain configWithWarn;
  };

  # NOTE: Test names _must_ start with `test` to be considered by `runTests`.
  # (note: numbers in test name used to ensure test ordering)
  tests = {
    # Test value propagation across config extensions
    "test.0initial" = {
      expr = configInit.val;
      expected = "first-value";
    };
    "test.1nested" = {
      expr = configNested.val;
      expected = "second-value, prev not used";
    };
    "test.2doubly-nested" = {
      expr = configNestedAgain.val;
      expected = "third-value (was second-value, prev not used)";
    };
    # Test nesting level info in kit state
    "test.0initial.level" = {
      expr = configInit._kitState.nestingLevel;
      expected = 0;
    };
    "test.1nested.level" = {
      expr = configNested._kitState.nestingLevel;
      expected = 1;
    };
    "test.2doubly-nested.level" = {
      expr = configNestedAgain._kitState.nestingLevel;
      expected = 2;
    };
    # Other tests
    "test.with-warning" = {
      expr = configWithWarn.warnings;
      # note: extensions are put before for list merges
      expected = [ "test warning is working" ];
    };
  };
  nicer_testResults = let
    testResults = pkgs.lib.runTests tests;
    fmtTestNames = lib.concatStringsSep ", " (builtins.attrNames tests);
  in (
    if testResults == []
    then "Tests successful ✨ (${fmtTestNames})"
    else testResults
  );

in nicer_testResults
# in evals # for DEBUG in repl

# Run with `nix eval -f $CURRENTFILE`
# Add `--json | jq .` for better readability of test result failures
