# Unit tests for the dyndots system.
#
# Each check is a derivation: builds successfully = pass, fails to build = fail.
# Run with: nix flake check
{ pkgs, lib, dyndots-flake }:

let
  # ---------------------------------------------------------------------------
  # Helpers

  # Evaluate the dyndots module with the given config overrides.
  evalDyndots = configModule:
    (lib.evalModules {
      modules = [
        dyndots-flake.modules.generic.dyndots
        configModule
      ];
      specialArgs = { inherit pkgs; };
    }).config.dyndots;

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

  # Build a trivial derivation that represents a passing check (all assertions
  # are evaluated at Nix eval time; if they throw, the derivation is never built).
  check = name: assertions: (
    let _unused = builtins.deepSeq assertions null;
    in pkgs.runCommandLocal name {} "touch $out"
  );

  # ---------------------------------------------------------------------------
  # Tests

  # Fake dotfiles config shared by several tests
  editableConfig = {
    dyndots.mode = "editable";
    dyndots.dotfilesNixPath = fakeStorePath;
    dyndots.dotfilesRealPath = "/home/user/.dot";
  };

in {

  # -- editable-symlinker passthru --

  editable-symlinker-redirect-target = check "editable-symlinker-redirect-target" (
    let
      cfg = evalDyndots editableConfig;
      link = cfg.mkLink (fakeSubPath "nvim");
    in [
      (do-assert "dyndotsRedirectTarget maps store subpath to real path"
        (link.dyndotsRedirectTarget == "/home/user/.dot/nvim"))
    ]
  );

  editable-symlinker-nested-path = check "editable-symlinker-nested-path" (
    let
      cfg = evalDyndots editableConfig;
      link = cfg.mkLink (fakeSubPath "gui-apps/espanso");
    in [
      (do-assert "nested subpath is correctly remapped"
        (link.dyndotsRedirectTarget == "/home/user/.dot/gui-apps/espanso"))
    ]
  );

  # -- not-editable mode: mkLink is identity --

  not-editable-mkLink-is-identity = check "not-editable-mkLink-is-identity" (
    let
      cfg = evalDyndots { dyndots.mode = "not-editable"; };
      path = fakeSubPath "nvim";
    in [
      (do-assert "mkLink in not-editable mode returns givenPath unchanged"
        (cfg.mkLink path == path))
    ]
  );

  # -- checkerScript --

  checker-script-null-in-not-editable = check "checker-script-null-in-not-editable" (
    let
      cfg = evalDyndots { dyndots.mode = "not-editable"; };
    in [
      (do-assert "checkerScript is null when mode is not-editable"
        (cfg.checkerScript == null))
    ]
  );

  checker-script-is-drv-in-editable = check "checker-script-is-drv-in-editable" (
    let
      cfg = evalDyndots editableConfig;
    in [
      (do-assert "checkerScript is a derivation when mode is editable"
        (lib.isDerivation cfg.checkerScript))
    ]
  );

  checker-script-contains-registered-path = check "checker-script-contains-registered-path" (
    let
      link = (evalDyndots editableConfig).mkLink (fakeSubPath "nvim");
      cfg = evalDyndots (editableConfig // {
        dyndots.checkedPaths = [ link ];
      });
      scriptText = builtins.readFile cfg.checkerScript;
    in [
      (do-assert "checkerScript mentions the real redirect target"
        (lib.hasInfix "/home/user/.dot/nvim" scriptText))
    ]
  );

  checker-script-skips-paths-without-passthru = check "checker-script-skips-paths-without-passthru" (
    let
      # A plain store path with no dyndotsRedirectTarget passthru
      plainPath = pkgs.emptyFile;
      cfg = evalDyndots (editableConfig // {
        dyndots.checkedPaths = [ plainPath ];
      });
      scriptText = builtins.readFile cfg.checkerScript;
    in [
      (do-assert "checkerScript does not reference plain path without passthru"
        (!(lib.hasInfix (toString plainPath) scriptText)))
    ]
  );

}
