let
  pkgs = builtins.getFlake "pkgs";

  kitsys = import ./. { lib = pkgs.lib; };

  minikit = kitsys.newKit (import ./minikit/kit.nix);

  firstEval = minikit.eval {
    inherit pkgs;
    config = {
      foo = "first-value";
    };
  };

  secondEval = firstEval.lib.extendWithPrevConfig ({lib, prevConfig, ...}: {
    foo = lib.mkForce "second-value (was ${prevConfig.foo})";
  });

  thirdEval = secondEval.lib.extendWithPrevConfig ({lib, prevConfig, ...}: {
    foo = lib.mkOverride 45 "third-value (was ${prevConfig.foo})";
    # note: mkForce has priority 50, 45 has more priority
  });

  extendOnlyEval = thirdEval.lib.extendWith ({lib, ...}: {
    foo = lib.mkOverride 40 "fourth-value (extend only)";
  });

  evalWithWarn = thirdEval.lib.extendWith ({lib, ...}: {
    warnings = [ "test warning is working" ];
  });

  testResults = pkgs.lib.runTests {
    test-initial-eval = {
      expr = firstEval.foo;
      expected = "first-value";
    };
    test-nested-eval = {
      expr = secondEval.foo;
      expected = "second-value (was first-value)";
    };
    test-doubly-nested-eval = {
      expr = thirdEval.foo;
      expected = "third-value (was second-value (was first-value))";
    };
    test-extend-only-eval = {
      expr = extendOnlyEval.foo;
      expected = "fourth-value (extend only)";
    };
    test-with-warning = {
      expr = evalWithWarn.warnings;
      # note: extensions are put before for list merges
      expected = [ "test warning is working" ];
    };
  };

in (
  if testResults == []
  then "Tests successful ✨"
  else testResults
)

# Run with `nix eval -f $CURRENTFILE`
# Add `--json | jq .` for better readability of test result failures
