{ lib, pkgs }:

{
  nvimConfigModule.nvim-minimal = ./nvim-minimal.nvim-config.nix;
  nvimConfigModule.nvim-bew = ./nvim-bew.nvim-config.nix;

  lib.evalNvimConfig = { pkgs, config, configOverride ? {} }: let
    toolConfigsFactory = import ./../nix/tool-configs-factory { inherit lib; };
  in toolConfigsFactory.lib.evalToolConfig {
    inherit pkgs config configOverride;
    toolBaseModule = ./_base.nvim-config.nix;
    toolName = "nvim";
  };
}
