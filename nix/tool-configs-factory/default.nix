{ lib }:

{
  # Eval a tool config!
  lib.evalToolConfig = {
    pkgs,
    toolName,
    configuration,
    toolBaseModule,
  }: let
    resolved = lib.evalModules {
      specialArgs.pkgs = pkgs;
      modules = [
        ./baseModule.nix
        toolBaseModule
        configuration
      ];
      class = "toolConfig.${toolName}";
    };
  in resolved.config;
}
