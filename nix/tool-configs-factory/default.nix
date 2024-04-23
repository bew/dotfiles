{ lib }:

{
  # Eval a tool config!
  lib.evalToolConfig = {
    pkgs,
    toolName,
    configuration,
  }: let
    resolved = lib.evalModules {
      specialArgs.pkgs = pkgs;
      modules = [
        ./baseModule.nix
        configuration
      ];
      class = "toolConfig.${toolName}";
    };
  in resolved.config;
}
