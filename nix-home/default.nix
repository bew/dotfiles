{ lib, ... }:

{
  imports = [
    # NOTE: I'l need to split more! (editor, shell, desktop, ....)
    ./cli.nix
    ./gui.nix
  ];

  # FIXME: uncomment when I'm in a release/channel!
  # meta.maintainers = [lib.maintainers.bew];

  # This value determines the Home Manager release that your configuration is
  # compatible with.
  # This helps avoid breakage when a new Home Manager release introduces
  # backwards incompatible changes.
  #
  # See the Home Manager release notes for a list of state version changes in
  # each release.
  home.stateVersion = "21.05";
}
