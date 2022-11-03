{ inputs
, system
, username
}:

# -------- Start of main home config module --------
{ config, pkgs, lib, ... }:

{
  imports = [
    ./modules/link-flake-inputs.nix
    ./modules/nix-registry.nix
    # Make (force) this home config install using `nix profile`, not `nix-env`
    ./modules/force-homemanager-to-use-nix-profiles.nix
  ] ++ [
    # NOTE: I'll need to split more! (editor, shell, desktop, ....)
    ./cli.nix
    ./gui.nix
  ];

  # -------- Push custom args for any of my modules --------

  _module.args.mybuilders = pkgs.callPackage ./mylib/mybuilders.nix {};

  # Flake inputs
  _module.args.flakeInputs = inputs;

  # Pkgs channels from inputs
  # => Allows to have a stable sharing point for multiple pkgs sets
  _module.args.pkgsChannels = let
    legacyPkgsForSystem = nixpkgs: nixpkgs.legacyPackages.${system};
    pkgsForSystem = nixpkgs: nixpkgs.packages.${system};
  in {
    backbone = legacyPkgsForSystem inputs.nixpkgsBackbone;
    stable = legacyPkgsForSystem inputs.nixpkgsStable;
    lastStable = legacyPkgsForSystem inputs.nixpkgsLastStable;
    bleedingedge = legacyPkgsForSystem inputs.nixpkgsUnstable;
    myPkgs = pkgsForSystem inputs.self;
  };

  # -------- Global home setup --------

  home.username = username;
  # Mark it as default, so I'll be able to override it for dev builds :)
  home.homeDirectory = lib.mkDefault "/home/${config.home.username}";

  # Link flake inputs to home
  # => Easy way to search/read/navigate in any of them
  linkFlakeInputs.directory = ".nix-home-current";

  # Restrict user nix/registry.json to the following indirect flakes:
  nixRegistry.indirectFlakes = {
    # -> flake ref: "path:${nixpkgs.outPath}"
    pkgs = { type = "path"; path = inputs.nixpkgsStable.outPath; };
    # -> flake ref: "github:nixos/nixpkgs/nixpkgs-unstable"
    unstable = {
      type = "github";
      owner = "nixos";
      repo = "nixpkgs";
      ref = "nixpkgs-unstable";
    };
    # -> flake ref: "path:${flakeTemplates.outPath}"
    templates = { type = "path"; path = inputs.flakeTemplates.outPath; };
  };

  # --------
  # Proof of concept of a dynamic/editable symlink-to-a-dot-file, managed by Nix, using
  # the `config.lib.file.mkOutOfStoreSymlink` helper function exposed by homeManager.
  home.file.".test-out-of-store-gitconfig".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dot/git/config";
  # NOTE: (for when I finally commit and have my home dot-files managed by Nix)
  # * https://github.com/nix-community/home-manager/issues/2085
  # * https://www.reddit.com/r/NixOS/comments/qlhifw/comment/hj32l2b/ (my own comment on the subject)
  home.file.".test-out-of-store-gitconfig--automatic".source = let
    # Allows to give a ./relative/path/value and have it automatically converted
    # to a path in my dotfiles directory. (Instead of being a path in the
    # nix-stored flake source: /nix/store/...-source)
    # FIXME: DOES NOT WORK ANYMORE?!
    linkToDots = pathRaw: let
      pathStr = toString pathRaw;
      flakeSourceDir = toString inputs.self; # same as `toString ./.` # Could be computed elsewhere
      actualDotsDir = "${config.home.homeDirectory}/.dot"; # Could be set in a custom module?

      pathRelativeToDots = lib.removePrefix (flakeSourceDir + "/") pathStr;
      pathAbsoluteToDots = "${actualDotsDir}/${pathRelativeToDots}";
    in config.lib.file.mkOutOfStoreSymlink pathAbsoluteToDots;
  in linkToDots ../../git/config;

  # Do not build home-manager's manual, it brings a number of useless dependencies and I don't need
  # them often anyway.
  manual.manpages.enable = false;

  # -------- Kind of 'meta' configs --------
  meta.maintainers = [lib.maintainers.bew];
  # This determines the home-manager release the config is compatible with.
  # Check home-manager release notes to see state version changes.
  home.stateVersion = "21.05";
}
