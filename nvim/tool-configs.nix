{ lib, pkgs }:

{
  nvimConfigModule.nvim-minimal = {
    imports = [ ./nvim-minimal.nvim-config.nix ];
  };
  nvimConfigModule.nvim-bew = {
    imports = [ ./nvim-bew.nvim-config.nix ];
  };

  lib.evalNvimConfig = { pkgs, configuration }: let
    toolConfigsFactory = import ./../nix/tool-configs-factory { inherit lib; };
  in toolConfigsFactory.lib.evalToolConfig {
    inherit pkgs configuration;
    toolBaseModule = ./_base.nvim-config.nix;
    toolName = "nvim";
  };
}
