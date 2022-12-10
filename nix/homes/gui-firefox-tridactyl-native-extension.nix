{ config, lib, pkgsChannels, ... }:

let
  cfg = config.my.firefox-tridactyl-native;
in
{
  options.my.firefox-tridactyl-native = {
    package = lib.mkOption {
      type = lib.types.package;
      description = ''Package tridactyl-native to use'';
    };
  };

  config = {
    # Ref: https://developer.mozilla.org/en-US/docs/Mozilla/Add-ons/WebExtensions/Native_messaging
    # Path found in: https://github.com/tridactyl/native_messenger/blob/62f19dba573b92/installers/install.sh#L29
    home.file.".mozilla/native-messaging-hosts/tridactyl.json" = {
      source = "${cfg.package}/lib/mozilla/native-messaging-hosts/tridactyl.json";
    };
  };
}
