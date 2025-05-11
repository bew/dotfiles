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

  secondEval = firstEval.lib.evalWithOverride ({lib, superConfig, ...}: {
    foo = lib.mkForce "second-value (was ${superConfig.foo})";
  });

  thirdEval = secondEval.lib.evalWithOverride ({lib, superConfig, ...}: {
    foo = lib.mkOverride 45 "third-value (was ${superConfig.foo})";
    # note: mkForce has priority 50, 45 has more priority
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
  };
in (
  if testResults == []
  then "Tests successful ✨"
  else testResults
)
# Run with `nix eval -f $CURRENTFILE`
# Add `--json | jq .` for better readability of test result failures
