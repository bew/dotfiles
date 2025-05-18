{ config, lib, pkgs, ... }:

let
  mybuilders = pkgs.callPackage ../nix/mylib/mybuilders.nix {};
  fs = lib.fileset;

  cfg = config;
  outs = cfg.outputs;
in {
  _class = "tool.tmux"; # type of nix module

  ID = "bew";

  outputs.editable-cfgDir = cfg.lib.mkLink ./.;

  # Only depend on conf files (skip Nix files to avoid useless rebuilds)
  outputs.non-editable-cfgDir = fs.toSource {
    root = ./.;
    fileset = fs.fileFilter (f: f.hasExt "conf") ./.;
  };

  editable.enable = true;
}
