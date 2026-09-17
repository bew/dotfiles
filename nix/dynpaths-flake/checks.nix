# Unit tests for the dynpaths system.
#
# Each check is a derivation: builds successfully = pass, fails to build = fail.
# Run with: nix flake check
{ pkgs, lib, dynpaths-flake }:

let
  # Evaluate the dynpaths module with the given config overrides.
  evalDynpaths = configModule:
    (lib.evalModules {
      modules = [
        dynpaths-flake.modules.generic.dynpaths
        configModule
      ];
      specialArgs = { inherit pkgs; };
    }).config.dynpaths;

  # Overlay `dynpaths` keys onto a config attrset.
  # Use this instead of `base // { dynpaths.x = ...; }`, which replaces the whole
  # `dynpaths` sub-attrset (top-level `//` is not a deep merge).
  overlayDynpaths = base: overrides: base // { dynpaths = base.dynpaths // overrides; };

  # A real store path usable as a fake nixStorePath.
  # We use pkgs.emptyFile — always in the store, always accessible.
  fakeStorePath = pkgs.emptyFile;

  # A fake sub-path inside the store source, like ./nvim resolved relative to flake root.
  fakeSubPath = name: "${fakeStorePath}/${name}";

  # Assert a condition at eval time; if false, throw with msg.
  do-assert = msg: cond: (
    if cond then true
    else throw "ASSERTION FAILED: ${msg}"
  );

  # Build a trivial derivation that represents a passing check.
  # The assertions must be deepSeq'd into the returned value, otherwise Nix's
  # laziness never forces them and every check passes vacuously.
  check = name: assertions:
    builtins.deepSeq assertions (pkgs.runCommandLocal name {} "touch $out");

  # Roots shared by most tests: one root `dots` over the whole fake source.
  baseRoots = {
    dots = {
      nixStorePath = fakeStorePath;
      realPath = "/home/user/.dot";
    };
  };

  # Dynamic config shared by several tests.
  dynamicConfig = {
    dynpaths.mode = "dynamic";
    dynpaths.roots = baseRoots;
  };

  # -------------------------------------------------------------------------
  # Symlink redirect resolution

in {

  redirect-target-maps-store-subpath = check "redirect-target-maps-store-subpath" (
    let
      cfg = evalDynpaths dynamicConfig;
      link = cfg.mkLink (fakeSubPath "nvim");
    in [
      (do-assert "dynpathRedirectTarget maps store subpath to real path"
        (link.dynpathRedirectTarget == "/home/user/.dot/nvim"))
      (do-assert "dynpathMatchedRoot reports the winning Root name"
        (link.dynpathMatchedRoot.name == "dots"))
    ]
  );

  redirect-target-nested-subpath = check "redirect-target-nested-subpath" (
    let
      cfg = evalDynpaths dynamicConfig;
      link = cfg.mkLink (fakeSubPath "gui-apps/espanso");
    in [
      (do-assert "nested subpath is correctly remapped"
        (link.dynpathRedirectTarget == "/home/user/.dot/gui-apps/espanso"))
    ]
  );

  longest-prefix-root-wins = check "longest-prefix-root-wins" (
    let
      cfg = evalDynpaths {
        dynpaths.mode = "dynamic";
        dynpaths.roots = baseRoots // {
          nvim-dev = {
            nixStorePath = "${fakeStorePath}/nvim";
            realPath = "/home/user/nvim-dev";
          };
        };
      };
      link = cfg.mkLink (fakeSubPath "nvim/lua/init.lua");
    in [
      (do-assert "nested Root beats its parent"
        (link.dynpathMatchedRoot.name == "nvim-dev"))
      (do-assert "nested Root remaps from its own realPath"
        (link.dynpathRedirectTarget == "/home/user/nvim-dev/lua/init.lua"))
    ]
  );

  parent-root-wins-outside-nested = check "parent-root-wins-outside-nested" (
    let
      cfg = evalDynpaths {
        dynpaths.mode = "dynamic";
        dynpaths.roots = baseRoots // {
          nvim-dev = {
            nixStorePath = "${fakeStorePath}/nvim";
            realPath = "/home/user/nvim-dev";
          };
        };
      };
      link = cfg.mkLink (fakeSubPath "gui-apps/espanso");
    in [
      (do-assert "parent Root wins when the nested Root does not prefix-match"
        (link.dynpathMatchedRoot.name == "dots"))
    ]
  );

  unmatched-path-is-store-link = check "unmatched-path-is-store-link" (
    let
      cfg = evalDynpaths dynamicConfig;
      path = "${pkgs.hello}/foo";
    in [
      (do-assert "no matching Root yields a Store copy (path unchanged)"
        (cfg.mkLink path == path))
    ]
  );

  no-path-component-boundary-match = check "no-path-component-boundary-match" (
    let
      cfg = evalDynpaths dynamicConfig;
      path = "${fakeStorePath}X/foo";
    in [
      (do-assert "a sibling path sharing a string prefix does NOT match"
        (cfg.mkLink path == path))
    ]
  );

  # -------------------------------------------------------------------------
  # Mode resolution

  static-mkLink-is-identity = check "static-mkLink-is-identity" (
    let
      cfg = evalDynpaths (overlayDynpaths dynamicConfig { mode = "static"; });
      path = fakeSubPath "nvim";
    in [
      (do-assert "mkLink in static mode returns givenPath unchanged"
        (cfg.mkLink path == path))
    ]
  );

  per-root-mode-overrides-global-static = check "per-root-mode-overrides-global-static" (
    let
      cfg = evalDynpaths {
        dynpaths.mode = "static";
        dynpaths.roots.dots = baseRoots.dots // { mode = "dynamic"; };
      };
      link = cfg.mkLink (fakeSubPath "nvim");
    in [
      (do-assert "per-Root mode dynamic wins over global static"
        (link.dynpathRedirectTarget == "/home/user/.dot/nvim"))
    ]
  );

  per-root-mode-overrides-global-dynamic = check "per-root-mode-overrides-global-dynamic" (
    let
      cfg = evalDynpaths {
        dynpaths.mode = "dynamic";
        dynpaths.roots.dots = baseRoots.dots // { mode = "static"; };
      };
      path = fakeSubPath "nvim";
    in [
      (do-assert "per-Root mode static wins over global dynamic"
        (cfg.mkLink path == path))
    ]
  );

  duplicate-storepath-throws = check "duplicate-storepath-throws" (
    let
      cfg = evalDynpaths {
        dynpaths.mode = "dynamic";
        dynpaths.roots = {
          a = { nixStorePath = fakeStorePath; realPath = "/home/user/a"; };
          b = { nixStorePath = fakeStorePath; realPath = "/home/user/b"; };
        };
      };
      result = builtins.tryEval (builtins.seq cfg.mkLink true);
    in [
      (do-assert "two Roots with the same nixStorePath throw at eval time"
        (!result.success))
    ]
  );

  # -------------------------------------------------------------------------
  # checkerScript

  checker-script-null-when-no-dynamic-root = check "checker-script-null-when-no-dynamic-root" (
    let
      cfg = evalDynpaths { dynpaths.mode = "static"; };
    in [
      (do-assert "checkerScript is null when mode is static"
        (cfg.checkerScript == null))
    ]
  );

  checker-script-null-when-roots-static = check "checker-script-null-when-roots-static" (
    let
      cfg = evalDynpaths {
        dynpaths.mode = "dynamic";
        dynpaths.roots.dots = baseRoots.dots // { mode = "static"; };
      };
    in [
      (do-assert "checkerScript is null when no Root resolves to dynamic"
        (cfg.checkerScript == null))
    ]
  );

  checker-script-is-drv-in-dynamic = check "checker-script-is-drv-in-dynamic" (
    let
      cfg = evalDynpaths dynamicConfig;
    in [
      (do-assert "checkerScript is a derivation when a Root is dynamic"
        (lib.isDerivation cfg.checkerScript))
    ]
  );

  checker-script-contains-target-and-root = check "checker-script-contains-target-and-root" (
    let
      link = (evalDynpaths dynamicConfig).mkLink (fakeSubPath "nvim");
      cfg = evalDynpaths (overlayDynpaths dynamicConfig {
        checkedPaths = [ link ];
      });
      scriptText = builtins.readFile cfg.checkerScript;
    in [
      (do-assert "checkerScript mentions the real redirect target"
        (lib.hasInfix "/home/user/.dot/nvim" scriptText))
      (do-assert "checkerScript mentions the winning Root name"
        (lib.hasInfix "matched root: dots" scriptText))
    ]
  );

  checker-script-skips-paths-without-passthru = check "checker-script-skips-paths-without-passthru" (
    let
      # A plain store path with no dynpathRedirectTarget passthru
      plainPath = pkgs.emptyFile;
      # Drop store-path context: lib.hasInfix builds a `builtins.match` pattern,
      # which rejects strings carrying store references.
      plainPathStr = lib.unsafeDiscardStringContext (toString plainPath);
      cfg = evalDynpaths (overlayDynpaths dynamicConfig {
        checkedPaths = [ plainPath ];
      });
      scriptText = builtins.readFile cfg.checkerScript;
    in [
      (do-assert "checkerScript does not reference plain path without passthru"
        (!(lib.hasInfix plainPathStr scriptText)))
    ]
  );

}
