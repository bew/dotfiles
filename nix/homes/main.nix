{
  flakeInputs,
  system,
  username,
}:

# -------- Start of main home config module --------
{ config, pkgs, lib, ... }:

{
  imports = [
    ../modules/generic/dyndots.nix
    ../modules/home/link-flake-inputs.nix
    ../modules/home/nix-registry.nix
  ] ++ [
    # NOTE: I'll need to split more! (editor, shell, desktop, ....)
    ./cli.nix
    ./gui.nix
  ];

  # -------- Push custom args for any of my modules --------

  _module.args.mybuilders = pkgs.callPackage ../mylib/mybuilders.nix {};

  # -------- Global home setup --------

  home.username = username;
  # Mark it as default, so I'll be able to override it for dev builds :)
  home.homeDirectory = lib.mkDefault "/home/${config.home.username}";

  # Configure my dotfiles path, so that direct links created with `config.dyndots.mkLink` point to
  # my repo (editable!).
  dyndots.mode = "editable";
  dyndots.dotfilesRealPath = "${config.home.homeDirectory}/.dot";
  dyndots.dotfilesNixPath = flakeInputs.self;

  # Link flake inputs to home
  # => Easy way to search/read/navigate in any of them
  linkFlakeInputs.enable = false;
  linkFlakeInputs.directory = ".nix-home-current";
  linkFlakeInputs.inputs = flakeInputs;

  # Restrict user nix/registry.json to the following indirect flakes:
  nixRegistry.indirectFlakes = {
    # -> flake ref: "path:${nixpkgs.outPath}"
    pkgs = { type = "path"; path = flakeInputs.nixpkgsStable.outPath; };
    # -> flake ref: "github:nixos/nixpkgs/nixpkgs-unstable"
    unstable = {
      type = "github";
      owner = "nixos";
      repo = "nixpkgs";
      ref = "nixpkgs-unstable";
    };
    # -> flake ref: "path:${flakeTemplates.outPath}"
    templates = { type = "path"; path = flakeInputs.flakeTemplates.outPath; };
  };

  # Do not build home-manager's manual, it brings a number of useless dependencies and I don't need
  # them often anyway.
  manual.manpages.enable = false;

  # -------- Kind of 'meta' configs --------
  meta.maintainers = [lib.maintainers.bew];
  # This determines the home-manager release the config is compatible with.
  # Check home-manager release notes to see state version changes.
  home.stateVersion = "21.05";
}
