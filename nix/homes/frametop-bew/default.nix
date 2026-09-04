{ config, ... }:

{
  imports = [
    ../../presets/home/common.nix

    # NOTE: I'll need to split more! (editor, shell, desktop, ....)
    ./cli.nix
    ./gui.nix
  ];
}
