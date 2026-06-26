{ config, lib, pkgs, ... }:

let
  mybuilders = pkgs.callPackage ../nix/mylib/mybuilders.nix {};
  fs = lib.fileset;

  cfg = config;
  outs = cfg.outputs;
in {
  _class = "tool.tmux"; # type of nix module

  ID = "bew";

  env.TMUX_PLUGIN_RESURRECT_PATH.set = let
    pluginDrv = pkgs.tmuxPlugins.resurrect.overrideAttrs (finalAttrs: {
      patches = [
        # Patch to add '@resurrect-hook-pre-save-all' hook exec
        # PR: https://github.com/tmux-plugins/tmux-resurrect/pull/574
        (pkgs.fetchpatch {
          url = "https://github.com/bew/tmux-resurrect/commit/258b32f4ed63b36043c3a63f69c427ae58b1b078.patch";
          hash = "sha256-ZOiy2hdyrxaXswaX/98fbt/fN4LSw8hp1ScJ8DPYFNA=";
        })
      ];
    });
  in "${pluginDrv}/share/tmux-plugins/resurrect";

  outputs.editable-cfgDir = cfg.lib.mkLink ./.;

  # Only depend on conf files and scripts (skip Nix files to avoid useless rebuilds)
  outputs.non-editable-cfgDir = fs.toSource {
    root = ./.;
    fileset = fs.unions [
      (fs.fileFilter (f: f.hasExt "conf") ./.)
      ./scripts
    ];
  };
}
