{ lib, ... }:

with lib;

{
  options = {
    pkgsChannels = mkOption {
      type = types.attrsOf (types.uniq types.attrs);
      default = {};
      description = ''
        This option aims to be a sharing point for multiple pkgs sets, identified by a unique name,
        to be used in other modules.
      '';
    };
  };
}
