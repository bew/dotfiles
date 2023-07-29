{ config, lib, pkgsChannels, ... }:

let
  cfg = config.my.firefox-native-extensions;
in
{
  options.my.firefox-native-extensions = {
    tridactyl-native = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      description = ''Package tridactyl-native to use'';
    };
    uget-integrator = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      description = ''Package uget-integrator to use'';
    };
  };

  config = {
    # Ref: https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Native_messaging
    # Path found in: https://github.com/tridactyl/native_messenger/blob/62f19dba573b92/installers/install.sh#L29
    # Plugin: https://addons.mozilla.org/en-US/firefox/addon/tridactyl-vim/
    home.file.".mozilla/native-messaging-hosts/tridactyl.json" = lib.mkIf (cfg.tridactyl-native != null) {
      source = "${cfg.tridactyl-native}/lib/mozilla/native-messaging-hosts/tridactyl.json";
    };

    # Plugin: https://addons.mozilla.org/en-US/firefox/addon/ugetintegration/
    home.file.".mozilla/native-messaging-hosts/com.ugetdm.firefox.json" = lib.mkIf (cfg.uget-integrator != null) {
      source = "${cfg.uget-integrator}/lib/mozilla/native-messaging-hosts/com.ugetdm.firefox.json";
    };
  };
}
