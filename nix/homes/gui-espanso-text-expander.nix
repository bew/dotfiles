# Module inspired from home-manager one:
# https://github.com/nix-community/home-manager/blob/master/modules/services/espanso.nix

{ config, lib, pkgs, ... }:

let
  cfg = config.my.services.espanso;
in {
  options.my.services.espanso = with lib; {
    enable = mkEnableOption "Espanso text expander";
    package = mkOption {
      type = types.package;
      description = "The package to use";
    };
    configDir = mkOption {
      type = types.nullOr types.path;
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "my.services.espanso" pkgs lib.platforms.linux)
      {
        assertion = lib.versionAtLeast cfg.package.version "2";
        message = ''
          The my.services.espanso module only supports Espanso version 2 or later.
        '';
      }
    ];

    xdg.configFile."espanso".source = lib.mkIf (cfg.configDir != null) cfg.configDir;

    # FIXME: remove from user-exposed packages? (but expose it another way?)
    home.packages = [ cfg.package ];

    systemd.user.services.espanso = {
      Unit = { Description = "Espanso: cross platform text expander in Rust"; };
      Service = {
        Type = "exec";
        ExecStart = "${cfg.package}/bin/espanso daemon";
        Restart = "on-failure";
      };
      Install = { WantedBy = [ "default.target" ]; };
    };
  };
}
