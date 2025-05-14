{ lib }:

{
  # Eval a tool config!
  lib.evalToolConfig = {
    pkgs,
    toolName,
    config,
    configOverride ? {},
    toolBaseModule,
  }: let
    resolved = lib.evalModules {
      specialArgs.pkgs = pkgs;
      modules = [
        ./baseModule.nix
        toolBaseModule
        config
        configOverride
      ];
      class = "tool.${toolName}";
    };
  in resolved.config;
}
