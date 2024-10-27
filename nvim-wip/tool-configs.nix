{ lib, pkgs }:

{
  nvimConfigModule.nvim-minimal = {
    imports = [
      ./_base.nvim-config.nix
      ./nvim-minimal.nvim-config.nix
    ];
  };
  # nvimConfigModule.nvim-bew = {
  #   imports = [
  #     ./_base.nvim-config-config.nix
  #     ./nvim-bew.nvim-config-config.nix
  #   ];
  # };

  lib.evalNvimConfig = { pkgs, configuration }: let
    toolConfigsFactory = import ./../nix/tool-configs-factory { inherit lib; };
  in toolConfigsFactory.lib.evalToolConfig {
    inherit pkgs configuration;
    toolName = "nvim";
  };
}
