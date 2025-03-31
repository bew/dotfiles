{ lib, pkgs }:

{
  zshConfigModule.zsh-bew = {
    imports = [ ./zsh-bew.zsh-config.nix ];
  };

  lib.evalZshConfig = { pkgs, configuration }: let
    toolConfigsFactory = import ./../nix/tool-configs-factory { inherit lib; };
  in toolConfigsFactory.lib.evalToolConfig {
    inherit pkgs configuration;
    toolBaseModule = ./_base.zsh-config.nix;
    toolName = "zsh";
  };
}
