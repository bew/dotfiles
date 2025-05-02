{ lib, pkgs }:

{
  zshConfigModule.zsh-bew = ./zsh-bew.zsh-config.nix;

  lib.evalZshConfig = { pkgs, config, configOverride ? {} }: let
    toolConfigsFactory = import ./../nix/tool-configs-factory { inherit lib; };
  in toolConfigsFactory.lib.evalToolConfig {
    inherit pkgs config configOverride;
    toolBaseModule = ./_base.zsh-config.nix;
    toolName = "zsh";
  };
}
